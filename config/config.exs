# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, level: :info

config :bonny,
  controllers: [
    EvictionOperator.Controller.V1.EvictionPolicy
  ]

import_config "#{Mix.env()}.exs"
