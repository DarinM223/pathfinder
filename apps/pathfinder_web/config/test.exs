import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pathfinder_web, PathfinderWeb.Web.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :pathfinder_web, PathfinderWeb.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "pathfinder_web_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :comeonin, bcrypt_log_rounds: 4, pbkdf5_rounds: 1
