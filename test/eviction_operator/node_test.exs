defmodule EvictionOperator.NodeTest do
  use ExUnit.Case, async: true
  doctest EvictionOperator.Node
  alias EvictionOperator.Node

  defmodule HTTPMock do
    @base_url "https://localhost:6443"

    def request(:get, @base_url <> "/api/v1/nodes", _, _, _) do
      data = %{"items" => ["foo", "bar"]}
      body = Jason.encode!(data)
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
    end
  end

  setup do
    K8s.Client.DynamicHTTPProvider.register(self(), __MODULE__.HTTPMock)
    :ok
  end

  def preferences(k, v) do
    [
      %{
        "preference" => %{
          "matchExpressions" => [
            %{"key" => k, "operator" => "In", "values" => [v]}
          ]
        },
        "weight" => 1
      }
    ]
  end

  describe "list/1" do
    test "lists nodes" do
      assert {:ok, ["foo", "bar"]} = Node.list(%{})
    end
  end

  describe "matches_preferences?" do
    test "" do
      node = %{
        "metadata" => %{
          "name" => "good-node",
          "labels" => %{"good" => "true"}
        }
      }

      assert Node.matches_preferences?(node, preferences("good", "true"))
    end
  end
end
