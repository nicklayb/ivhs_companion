import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


config :companion, Companion.Mqtt,
  adapter:
    {IvhsBroker.Mqtt.Adapter.Mqttx,
     handler: IvhsBroker.Mqtt.Adapter.Mqttx.Handler, handler_state: %{}}
