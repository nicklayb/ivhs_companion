defmodule Companion.Uart do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(_args) do
    if enabled?() do
      children = adapter_children() ++ [{Companion.Uart.Handler, adapter: adapter()}]

      Supervisor.init(children, strategy: :one_for_all)
    else
      :ignore
    end
  end

  defp adapter_children do
    {adapter, options} = adapter()

    adapter.children(options)
  end

  defp adapter do
    :companion
    |> Application.fetch_env!(Companion.Uart)
    |> Keyword.fetch!(:adapter)
  end

  defp enabled? do
    :companion
    |> Application.fetch_env!(Companion.Uart)
    |> Keyword.fetch!(:enabled)
  end
end
