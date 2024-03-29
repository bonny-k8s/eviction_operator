defmodule EvictionOperator.Eviction do
  @moduledoc """
  Encapsulates a Kubernetes [`Eviction` resource](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.14/#create-eviction-pod-v1-core)

  ## Links

  * [Eviction API](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#the-eviction-api)
  """

  require Logger
  alias __MODULE__
  @api_version "policy/v1beta1"

  @doc """
  Returns an `Eviction` Kubernetes manifest

  ## Examples
      iex> EvictionOperator.Eviction.manifest("default", "aged-nginx")
      %{"apiVersion" => "policy/v1beta1", "kind" => "Eviction", "metadata" => %{"name" => "aged-nginx", "namespace" => "default"}}
  """
  @spec manifest(binary, binary) :: map
  def manifest(namespace, name) do
    %{
      "apiVersion" => @api_version,
      "kind" => "Eviction",
      "metadata" => %{
        "namespace" => namespace,
        "name" => name
      }
    }
  end

  @doc "Creates a pod eviction."
  @spec create(map) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def create(%{"metadata" => %{"name" => name, "namespace" => ns}} = pod) do
    eviction = Eviction.manifest(ns, name)
    operation = K8s.Client.create("v1", "pods/eviction", [namespace: ns, name: name], eviction)

    {duration, response} = :timer.tc(K8s.Client, :run, [operation, :default])
    node_name = get_in(pod, ["spec", "nodeName"])

    measurements = %{duration: duration}
    metadata = %{node: node_name, pod: name}

    case response do
      {:ok, _} = resp ->
        EvictionOperator.Event.pod_eviction_succeeded(measurements, metadata)
        resp

      error ->
        EvictionOperator.Event.pod_eviction_failed(measurements, metadata)
        error
    end
  end
end
