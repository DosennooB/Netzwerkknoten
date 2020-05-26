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
  def start_routingtable do
      receive do
        {:conection_pid, con_pid} ->
          send con_pid, {:get_routingtable, self()}

          receive do
            {:set_routingtable, table} ->
              link_pid = spawn_link(fn -> Link_Verteiler.start_link_verteiler() end)
              routingtable(link_pid, con_pid, table)
          end
      end
  end

  defp routingtable(link_pid, con_pid, table) do
    receive do
      {:rout_get_routingtable, pid} ->
        send pid, {:rout_routingtable, table}
        routingtable(link_pid, con_pid, table)

      {:rout_set_routingtable, con_pid, table_new} ->
        routingtable(link_pid, con_pid, table_new)

      {:rout_message, m = %Message{}} ->
        hop = Keyword.get_values(table, m.receiver)
        send link_pid, {:sending, hop, m}

      {:rout_broadcast, m = %Message{}} ->
        send link_pid, {:broadcast, m}

      {:conection_pid, con_pid_new} ->
        routingtable(link_pid, con_pid_new, table)
    end
  end
end
