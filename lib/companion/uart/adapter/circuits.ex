defmodule Companion.Uart.Adapter.Circuits do
  @behaviour Companion.Uart.Adapter
  @name __MODULE__

  @impl Companion.Uart.Adapter
  def init(options) do
    device_identifier = Keyword.fetch!(options, :device)
    baud_rate = Keyword.fetch!(options, :baud_rate)

    with {:ok, device} <- find_device(device_identifier),
         :ok <-
           Circuits.UART.open(@name, device, speed: baud_rate, active: true) do
      {:ok, %{device: device}}
    end
  end

  @impl Companion.Uart.Adapter
  def children(_options) do
    [
      {Circuits.UART, name: @name}
    ]
  end

  @impl Companion.Uart.Adapter
  def handle_message({:circuits_uart, device, message}, %{device: device}) do
    case decode_payload(message) do
      {:ok, json_payload} -> {:ok, json_payload}
      _ -> :ignore
    end
  end

  def handle_message(_, _state), do: :ignore

  defp decode_payload("{" <> _ = json_payload), do: JSON.decode(json_payload)
  defp decode_payload(_), do: {:error, :invalid_payload}

  defp find_device(device) do
    [vendor_id, product_id] =
      device
      |> String.split(":", parts: 2)
      |> Enum.map(fn part ->
        {part, _} = Integer.parse(part, 16)
        part
      end)

    Circuits.UART.enumerate()
    |> Enum.find_value(fn
      {device_name, %{vendor_id: ^vendor_id, product_id: ^product_id}} ->
        device_name

      _ ->
        nil
    end)
    |> Box.Result.from_nil(:no_such_device)
  end
end
