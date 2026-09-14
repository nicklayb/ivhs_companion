defmodule Companion.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Companion.Uart,
      Companion.Mqtt.Client,
    ]

    opts = [strategy: :one_for_one, name: Companion.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
