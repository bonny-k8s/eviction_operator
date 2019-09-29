defmodule EvictionOperator.PodTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest EvictionOperator.Pod
  alias EvictionOperator.Pod

  defmodule HTTPMock do
    @base_url "https://localhost:6443"

    def pod(name, age_in_seconds) do
      start_time = DateTime.utc_now() |> DateTime.add(-age_in_seconds, :second)
      pod = K8s.Resource.build("v1", "Pod", "default", name)

      pod
      |> Map.put("status", %{})
      |> put_in(["status", "startTime"], start_time)
    end

    def request(:get, @base_url <> "/api/v1/pods", _, _, _) do
      pod1 = pod("new", 0)
      pod2 = pod("old", 300)
      data = %{"items" => [pod1, pod2]}
      body = Jason.encode!(data)
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
    end

    def request(:get, @base_url <> "/api/v1/nodes", _, _, _) do
      node = K8s.Resource.build("v1", "Node", "n1-standard-1")
      data = %{"items" => [node]}
      body = Jason.encode!(data)
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
    end
  end

  setup do
    K8s.Client.DynamicHTTPProvider.register(self(), __MODULE__.HTTPMock)
    :ok
  end

  test "candidates/1" do
    assert {:ok, stream} = Pod.candidates(policy())
    [pod1, pod2] = Enum.into(stream, [])
    assert %{"metadata" => %{"name" => "new"}} = pod1
    assert %{"metadata" => %{"name" => "old"}} = pod2
  end

  test "evictable/1" do
    assert {:ok, stream} = Pod.evictable(policy())
    pods = Enum.into(stream, [])
    assert length(pods) == 1
    pod = List.first(pods)
    assert %{"metadata" => %{"name" => "old"}} = pod
  end

  def policy() do
    yaml = """
    apiVersion: eviction-operator.bonny.run/v1
    kind: EvictionPolicy
    metadata:
      name: all-nginx
    spec:
      mode: all
      maxLifetime: 300
      selector:
        matchLabels:
          app: nginx
    """

    YamlElixir.read_from_string!(yaml)
  end
end
