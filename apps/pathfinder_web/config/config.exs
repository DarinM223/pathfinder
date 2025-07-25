# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :pathfinder_web,
  namespace: PathfinderWeb,
  ecto_repos: [PathfinderWeb.Repo]

# Configures the endpoint
config :pathfinder_web, PathfinderWeb.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "LVsqR4fDZJxgD7NCOIw6EXGRgNSVJgJYX7q2dDyQnZM63ZokbXEJprOH5Wbt0mo9",
  render_errors: [view: PathfinderWeb.Web.ErrorView, accepts: ~w(html json)],
  pubsub_server: PathfinderWeb.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.5",
  default: [
    args: ~w(js/app.jsx --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
