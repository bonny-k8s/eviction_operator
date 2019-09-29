defmodule EvictionOperator.EvictionTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest EvictionOperator.Eviction
  alias EvictionOperator.Eviction

  defmodule HTTPMock do
    @base_url "https://localhost:6443"

    def request(:post, @base_url <> "/api/v1/namespaces/default/pods/nginx/eviction", _, _, _) do
      data = %{"test" => "ok"}
      body = Jason.encode!(data)
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
    end
  end

  setup do
    K8s.Client.DynamicHTTPProvider.register(self(), __MODULE__.HTTPMock)
    :ok
  end

  describe "create/1" do
    test "creates a pod eviction" do
      pod = %{
        "metadata" => %{
          "name" => "nginx",
          "namespace" => "default"
        }
      }

      assert {:ok, %{"test" => "ok"}} = Eviction.create(pod)
    end
  end
end
