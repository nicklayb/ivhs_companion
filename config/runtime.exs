import Config

adapter =
  case config_env() do
    :test ->
      {}

    _ ->
      {Companion.Uart.Adapter.Circuits,
       device: Box.Config.get("TTY_DEVICE", default: "239a:8029"),
       baud_rate: Box.Config.int("TTY_BAUD_RATE", default: "115200")}
  end

config(:companion, Companion.Uart,
  enabled: Box.Config.bool("UART_ENABLED", default: "true"),
  adapter: adapter
)

config :logger, level: Box.Config.atom("LOGGER_LEVEL", default: "info")

config :companion, Companion.Mqtt,
  host: Box.Config.get("MQTT_HOST", default: "localhost"),
  port: Box.Config.int("MQTT_PORT", default: "1883"),
  client_id: Box.Config.get("MQTT_CLIENT_ID", default: "ivhs"),
  username: Box.Config.get("MQTT_USERNAME"),
  password: Box.Config.get("MQTT_PASSWORD")
