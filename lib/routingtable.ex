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

  - tabel ist eine Map die aus den Ziel_pid (key) und dem dazu gehörigen Hop_pid (value) besteht

  - hopptable (key) die Hopp_pid (value) die kosten der Hoppverbindungen
  """
  @type con_pid :: pid()
  @type link_pid :: pid()
  @type table :: %{pid()=> pid()}
  @type hoptable :: map()

  @doc """
  Startet den Prozess in dem es die PID des Prozesses connection bekommt und
  und eine Touting tablle bekommet
  """
  def start_routingtable() do
    receive do
      {:conection_pid, con_pid} ->
        receive do
          {:rout_set_routingtable, ^con_pid, table, hoptable} ->
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
        vergleicheRoutingtable(link_pid, hoptable, hoptable_new, Map.keys(hoptable_new))
        routingtable(link_pid, con_pid, table_new, hoptable_new)

      {:rout_message, m = %Message{}} ->
        hop = Map.get_lazy(table, m.receiver, fn ->
          Map.values(table)|> Enum.random()
        end)
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

  defp vergleicheRoutingtable(link_pid, hoptable, hoptable_new, [h|t]) do
    {x,ht} = Map.pop(hoptable, h, nil)
    {y,htn} = Map.pop(hoptable_new, h, nil)
    cond do
      x==y ->
        nil
      true ->
        send(link_pid, {:CreateUpdate_link, h, y})
    end
    vergleicheRoutingtable(link_pid, ht, htn, t)
  end

  defp vergleicheRoutingtable(link_pid, hoptable, _hoptable_new, []) do
    Enum.map(hoptable, fn{k,_v} -> send(link_pid, {:kill_link, k}) end )
  end
end
