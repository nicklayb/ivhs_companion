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
