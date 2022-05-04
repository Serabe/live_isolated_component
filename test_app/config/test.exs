import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :test_app, TestAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "tkjO//XAMBt4D6C7CxUlevjnXVOYo1GicmfoBOwcQg6PRzD7xsz7By5v475EhVyv",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
