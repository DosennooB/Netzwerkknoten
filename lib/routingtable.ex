defmodule Routingtable do
  @moduledoc """
  Modul sogrt für die verwaltung der Routingtabelle und controliert die Linkverteiler

  ## Parameter
  - {:rout_get_routingtable, pid} : gibt die Routingtable zurück an der Sender

  - {:rout_set_routingtable, con_pid, table_new} : setzt die Routingtable des Prozesses neu wen sie
  von Connection kommt

  - {:rout_message, m = %Message{}} : ermittelt den nächsten hop vom Weg zu ziel und gibt die nachricht zur
  weiteren Verarbeitung weiter

  - {:rout_broadcast, m = %Message{}} : gibt die Nachricht an alle weiteren angeschlossenen Router weiter

  - {:conection_pid, con_pid_new} : bekommt einen neue PID des Connection Prozesses

  """
  def start_routingtable() do
    receive do
      {:conection_pid, con_pid} ->
        send(con_pid, {:get_routingtable, self()})

        receive do
          {:set_routingtable, ^con_pid, table, hoptable} ->
            link_pid = spawn_link(fn -> Link_Verteiler.start_link_verteiler() end)
            initRoutingtable(link_pid, hoptable)
            routingtable(link_pid, con_pid, table, hoptable)
        end
    end
  end

  defp routingtable(link_pid, con_pid, table, hoptable) do
    receive do
      {:rout_get_routingtable, pid} ->
        send(pid, {:rout_routingtable, table})
        routingtable(link_pid, con_pid, table, hoptable)

      {:rout_set_routingtable, ^con_pid, table_new, hoptable_new} ->
        # TODO setting new hops for link pid
        routingtable(link_pid, con_pid, table_new, hoptable_new)

      {:rout_message, m = %Message{}} ->
        hop = Map.get(table, m.receiver)
        send(link_pid, {:sending, hop, m})
        routingtable(link_pid, con_pid, table, hoptable)

      {:rout_broadcast, m = %Message{}} ->
        send(link_pid, {:broadcast, m})
        routingtable(link_pid, con_pid, table, hoptable)

      {:conection_pid, con_pid_new} ->
        routingtable(link_pid, con_pid_new, table, hoptable)
    end
  end

  defp initRoutingtable(link_pid, hoptable) do
    k = Map.keys(hoptable)
    initRoutingtable(link_pid, hoptable, k)
  end

  defp initRoutingtable(link_pid, hoptable, [h | t]) do
    kosten = Map.get(hoptable, h)
    send(link_pid, {:CreateUpdate_link, h, kosten})
    initRoutingtable(link_pid, hoptable, t)
  end

  defp initRoutingtable(_link_pid, _hoptable, []) do
  end

  defp vergleicheRoutingtable(link_pid, hoptabel, hoptable_new) do
    #TODO vergleich für set table
  end
end
