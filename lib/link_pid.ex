defmodule Link_pid do
  @moduledoc """
  Das Modul dient dazu Nachrichen mit der
  gewünschten Verzögerung abzuschicken.

  ## Parameter
  - {:sending, Message} : sendet die Message an den nächsten Router.
  Verringert die ttl

  - {:updating_kost , value} : ändert die Link kosten für die
  Verbindung zum Router

  - {:get_kost, pid} : gibt die kosten für die Link verbindung zurück

  - {:kill, pid} : beendet den Prozess
  """

  def start_link(link_pid, link_kost) do
    link(link_pid, link_kost)
  end

  defp link(link_pid, link_kost) do
    receive do
      {:sending, m = %Message{}} ->
        if m.ttl != 1 do
          Process.sleep(m.size * link_kost)
          send(link_pid, {:packet, self(), %{m | ttl: m.ttl - 1}})
          link(link_pid, link_kost)
        end

      {:updating_kost, value} ->
        link(link_pid, value)

      {:get_kost, pid} ->
        send(pid, {:kosten, self(), link_pid, link_kost})

      {:kill, pid} ->
        if pid != self() do
          link(link_pid, link_kost)
        end
    end
  end
end
