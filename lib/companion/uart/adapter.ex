defmodule Companion.Uart.Adapter do
  @type options :: Keyword.t()
  @callback init(options()) :: {:ok, map()} | {:error, any()}

  @callback children(options()) :: [Supervisor.child_spec()]

  @callback handle_message(any(), options()) :: {:ok, map()} | {:error, any()} | :ignore
end
