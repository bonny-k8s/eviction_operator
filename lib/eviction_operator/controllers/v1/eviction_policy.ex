defmodule EvictionOperator.Controller.V1.EvictionPolicy do
  @moduledoc "EvictionOperator: EvictionPolicy CRD."
  use Bonny.Controller

  @group "eviction-operator.bonny.run"
  @version "v1"
  @scope :cluster
  @names %{
    plural: "evictionpolicies",
    singular: "evictionpolicy",
    kind: "EvictionPolicy",
    shortNames: ["ep"]
  }

  @rule {"", ["nodes"], ["list"]}
  @rule {"", ["pods"], ["list"]}
  @rule {"", ["pods/eviction"], ["create"]}

  @additional_printer_columns [
    # %{
    #   name: "test",
    #   type: "string",
    #   description: "test",
    #   JSONPath: ".spec.test"
    # }
  ]

  @doc "Handles an `ADDED` event"
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(payload), do: handle_eviction(payload)

  @doc "Handles a `MODIFIED` event"
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(payload), do: handle_eviction(payload)

  @doc "Handles a `DELETED` event"
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(_), do: :ok

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(payload), do: handle_eviction(payload)

  @doc false
  @spec handle_eviction(map()) :: :ok | :error
  def handle_eviction(%{} = policy) do
    with {:ok, pods} <- EvictionOperator.Pod.evictable(policy) do
      Enum.each(pods, &EvictionOperator.Eviction.create/1)
      :ok
    end
  end

  def handle_eviction(_), do: :error
end
