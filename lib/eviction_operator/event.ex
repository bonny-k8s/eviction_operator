defmodule EvictionOperator.Event do
  @moduledoc false
  use Notion, name: :"eviction-operator", metadata: %{}

  defevent([:pod, :eviction, :succeeded])
  defevent([:pod, :eviction, :failed])

  defevent([:nodes, :list, :succeeded])
  defevent([:nodes, :list, :failed])

  defevent([:pods, :list_candidates, :succeeded])
  defevent([:pods, :list_candidates, :failed])
end
