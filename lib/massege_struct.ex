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
  @enforce_keys [:receiver, :sender, :type]
  defstruct [:receiver, :sender, :type, :data, :size, ttl: 64]
end
