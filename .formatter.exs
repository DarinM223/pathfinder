[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "mix.exs",
    "*.{heex,ex,exs}",
    "apps/*/*.{heex,ex,exs}",
    "apps/*/{lib,test,config}/**/*.{heex,ex,exs}",
    "apps/*/mix.exs",
    "apps/*/priv/*/seeds.exs"
  ]
]
