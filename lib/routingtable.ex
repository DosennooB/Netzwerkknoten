defmodule Routingtable do
  def start_routingtable do

    receive do
      {:link_verteiler_pid, link_pid} ->

        receive do
          {:conection_pid, con_pid} ->
            send con_pid, {:get_routingtable, self()}

            receive do
              {:set_routingtable, table = []} ->
                routingtable(link_pid, con_pid, table)
            end
        end
    end
  end

  defp routingtable(link_pid, con_pid, table) do
    receive do
      {:rout_get_routingtable, pid} ->
        send pid, {:rout_routingtable, table}
    end

  end
end
