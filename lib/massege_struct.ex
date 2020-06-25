defmodule Message do
  @moduledoc """
  ## Parameters
    - receiver: Pid des Empfangs router
    - sender: Pid des Sender Routers
    - type: art der Nachricht
    - data: nutzlast
    - size: vorberechnete Größe
    - ttl: Die maximale Hopp dauer
  """
  @doc """
  type kann sein :new_link, :del_link
  """
  @type type :: atom()
  @enforce_keys [:receiver, :sender, :type]
  defstruct [:receiver, :sender, :type, :data, :size, ttl: 64]
end
