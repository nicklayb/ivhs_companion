defmodule Companion.Uart.Handler do
  use GenServer

  require Logger

  @retry_timer :timer.seconds(5)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    adapter = Keyword.fetch!(args, :adapter)
    send(self(), :open)
    {:ok, %{adapter: adapter}}
  end

  def handle_info(:open, %{adapter: {adapter, adapter_options}} = state) do
    case adapter.init(adapter_options) do
      {:ok, adapter_state} ->
        Logger.info("[#{inspect(__MODULE__)}] [#{inspect(adapter)}.init] opened")

        new_state =
          Map.put(state, :adapter_state, Map.put(adapter_state, :options, adapter_options))

        {:noreply, new_state}

      {:error, error} ->
        Logger.error(
          "[#{inspect(__MODULE__)}] [#{inspect(adapter)}.init] #{inspect(error)}, retrying in #{@retry_timer}ms"
        )

        Process.send_after(self(), :open, @retry_timer)
        {:noreply, state}
    end
  end

  def handle_info({:forward, message}, state) do
    Logger.info("[#{inspect(__MODULE__)}] [forward] #{inspect(message)}")
    {:noreply, state}
  end

  def handle_info(message, %{adapter: {adapter, _}} = state) do
    Logger.debug(
      "[#{inspect(__MODULE__)}] [#{inspect(adapter)}] [handle_info] #{inspect(message)}"
    )

    state =
      case adapter.handle_message(message, state.adapter_state) do
        {:ok, message} ->
          send(self(), {:forward, message})
          state

        {:error, error} ->
          Logger.warning(
            "[#{inspect(__MODULE__)}] [#{inspect(adapter)}.handle] #{inspect(error)}"
          )

          state

        :ignore ->
          state
      end

    {:noreply, state}
  end
end
