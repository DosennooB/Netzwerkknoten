defmodule Link_Verteiler do
  @moduledoc """
  Modul verteilt die Nachrichten an ihre
  angeschlossenen Links zum versenden.

  ## Parameter
  - {:CreateUpdate_link, next_hop, link_kost} : Inizialisiert einen neuen Link
  mit entsprechenden Kosten. Wenn Link vorhanden ist dann Updatet die kosten

  - {:sending, next_hop, from_pid, Message} : Wählt den Passenden Link für das senden der Nachricht aus.

  - {:broadcast, from_pid, Message} : Sendet eine Nachricht an alle verbundenen Links

  - {:kill_link, next_hop} : Löst einen Link zu einen Router auf.
  """
  def start_link_verteiler do
    verteiler(%{})
  end

  defp verteiler(pidzuRouter) do
    receive do
      {:CreateUpdate_link, next_hop, link_kost} ->
        cond do
          Map.has_key?(pidzuRouter, next_hop) ->
            Map.get(pidzuRouter, next_hop) |>
            send({:updating_kost, link_kost})
            verteiler(pidzuRouter)

          true ->
            pid = spawn_link(fn -> Link_pid.start_link(next_hop, link_kost) end)
            verteiler(Map.put(pidzuRouter, next_hop, pid))
        end

      {:sending, next_hop,  m = %Message{}} ->
        Map.get(pidzuRouter, next_hop) |>
        send( {:sending, m})
        verteiler(pidzuRouter)

      {:broadcast,  m = %Message{}} ->
        Map.values(pidzuRouter)|>
        broadcast( m)
        verteiler(pidzuRouter)

      {:kill_link, next_hop} ->
        link_pid = Map.get(pidzuRouter, next_hop)
        send(link_pid, {:kill, link_pid})
        verteiler(Map.delete(pidzuRouter, next_hop))

    end
  end
#TODO wenn ein fehler passiert an alle links das Kill Signal senden
  defp broadcast([h | t], m = %Message{}) do
    send(h, {:sending, m})
    broadcast(t, m)
  end

  defp broadcast([], _Message) do
  end
end
