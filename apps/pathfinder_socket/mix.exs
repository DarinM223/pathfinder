defmodule PathfinderSocket.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pathfinder_socket,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PathfinderSocket, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
      {:phoenix, "~> 1.7.0"},
      {:gettext, "~> 0.9"},
      {:plug_cowboy, "~> 2.1"},
      {:phoenix_gen_socket_client, "~> 4.0.0"},
      {:websocket_client, "~> 1.2"},
      {:pathfinder, in_umbrella: true}
    ]
  end
end
