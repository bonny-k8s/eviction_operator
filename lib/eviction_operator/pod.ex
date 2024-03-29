defmodule EvictionOperator.Pod do
  @moduledoc """
  Finds pods that are candidates for eviction.
  """

  @default_max_lifetime 600

  alias K8s.{Client, Operation, Selector}
  alias EvictionOperator.{Node, Event}

  @doc """
  Gets all pods with eviction enabled.
  """
  @spec candidates(map()) :: {:ok, Enumerable.t()} | {:error, HTTPoison.Response.t()}
  def candidates(%{} = policy) do
    op = Client.list("v1", :pods, namespace: :all)
    selector = Selector.parse(policy)
    op_w_selector = %Operation{op | label_selector: selector}

    response = Client.stream(op_w_selector, :default)

    case response do
      {:ok, stream} ->
        Event.pods_list_candidates_succeeded(%{}, %{})
        {:ok, stream}

      {:error, _any} = error ->
        Event.pods_list_candidates_failed(%{}, %{})
        error
    end
  end

  @doc """
  Get a list of evictable pods on the given node pool.

  Filters `candidates/1` by `pod_started_before/1` and optionally `on_nonpreferred_node/N`
  """
  @spec evictable(map) :: {:ok, Enumerable.t()} | {:error, HTTPoison.Response.t()}
  def evictable(%{} = policy) do
    with {:ok, nodes} <- Node.list(),
         {:ok, stream} <- candidates(policy) do
      max_lifetime = max_lifetime(policy)
      started_before = pods_started_before(stream, max_lifetime)

      ready_for_eviction =
        case mode(policy) do
          :all -> started_before
          :nonpreferred -> pods_on_nonpreferred_node(started_before, nodes)
        end

      {:ok, ready_for_eviction}
    end
  end

  @spec pods_on_nonpreferred_node(Enumerable.t(), list(map)) :: Enumerable.t()
  defp pods_on_nonpreferred_node(pods, nodes) do
    Stream.filter(pods, fn pod -> pod_on_nonpreferred_node(pod, nodes) end)
  end

  @doc false
  @spec pods_started_before(Enumerable.t(), pos_integer) :: Enumerable.t()
  def pods_started_before(pods, max_lifetime) do
    Stream.filter(pods, fn pod -> pod_started_before(pod, max_lifetime) end)
  end

  @spec pod_on_nonpreferred_node(map, list(map)) :: boolean
  def pod_on_nonpreferred_node(
        %{
          "spec" => %{
            "nodeName" => node_name,
            "affinity" => %{
              "nodeAffinity" => %{"preferredDuringSchedulingIgnoredDuringExecution" => affinity}
            }
          }
        },
        nodes
      ) do
    prefs = Enum.map(affinity, fn a -> Map.get(a, "preference") end)

    preferred =
      nodes
      |> find_node_by_name(node_name)
      |> Node.matches_preferences?(prefs)

    !preferred
  end

  def pod_on_nonpreferred_node(_pod_with_no_affinity, _nodes), do: false

  @spec find_node_by_name(list(map), binary()) :: map() | nil
  defp find_node_by_name(nodes, node_name) do
    Enum.find(nodes, fn %{"metadata" => %{"name" => name}} -> name == node_name end)
  end

  @doc """
  Check if a pod started before a given time

  ## Examples
      iex> start_time = DateTime.utc_now |> DateTime.add(-61, :second) |> DateTime.to_string
      ...> EvictionOperator.Pod.pod_started_before(%{"status" => %{"startTime" => start_time}}, 60)
      true

      iex> start_time = DateTime.utc_now |> DateTime.to_string
      ...> EvictionOperator.Pod.pod_started_before(%{"status" => %{"startTime" => start_time}}, 60)
      false
  """
  @spec pod_started_before(map, pos_integer) :: boolean
  def pod_started_before(%{"status" => %{"startTime" => start_time}}, seconds) do
    seconds_ago = -parse_seconds(seconds)
    cutoff_time = DateTime.utc_now() |> DateTime.add(seconds_ago, :second)

    with {:ok, start_time, _} <- DateTime.from_iso8601(start_time),
         :lt <- DateTime.compare(start_time, cutoff_time) do
      true
    else
      _ -> false
    end
  end

  def pod_started_before(_, _), do: false

  @spec max_lifetime(map()) :: pos_integer()
  defp max_lifetime(%{"spec" => %{"maxLifetime" => sec}}), do: parse_seconds(sec)
  defp max_lifetime(_), do: @default_max_lifetime

  @spec mode(map()) :: :all | :nonpreferred
  defp mode(%{"spec" => %{"mode" => "nonpreferred"}}), do: :nonpreferred
  defp mode(_), do: :all

  @spec parse_seconds(binary() | pos_integer() | {pos_integer(), term()}) :: pos_integer()
  defp parse_seconds(sec) when is_binary(sec), do: sec |> Integer.parse() |> parse_seconds
  defp parse_seconds(sec) when is_integer(sec), do: sec
  defp parse_seconds({sec, _}), do: sec
  defp parse_seconds(_), do: 0
end
