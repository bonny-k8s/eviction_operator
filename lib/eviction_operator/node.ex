defmodule EvictionOperator.Node do
  @moduledoc """
  Encapsulates a Kubernetes [`Node` resource](https://kubernetes.io/docs/concepts/architecture/nodes/).
  """

  alias K8s.{Client, Selector}
  alias EvictionOperator.Event

  @doc """
  List kubernetes nodes.
  """
  @spec list(map()) :: {:ok, list(map)} | :error
  def list(params \\ %{}) do
    op = Client.list("v1", :nodes)

    with {:ok, stream} <- Client.stream(op, :default, params: params) do
      {duration, nodes} = :timer.tc(Enum, :into, [stream, []])
      measurements = %{duration: duration, count: length(nodes)}
      Event.nodes_list_succeeded(measurements, %{})

      {:ok, nodes}
    else
      _error ->
        Event.nodes_list_failed(%{}, %{})
        :error
    end
  end

  # Currently only supports matchExpressions (not matchFields)
  # Also ignores weight of preferences
  @doc false
  @spec matches_preferences?(map, list(map)) :: boolean
  def matches_preferences?(node, prefs) do
    Enum.any?(prefs, fn pref ->
      exprs = Map.get(pref, "matchExpressions", [])
      Selector.match_expressions?(node, exprs)
    end)
  end
end
