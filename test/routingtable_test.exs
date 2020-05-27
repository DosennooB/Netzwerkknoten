defmodule Routingtable_test do
  use ExUnit.Case, async: true
  doctest Routingtable

  @tag timeout: 3000
  test "gebe Routingtable zurück" do
    routing_pid = startup()
    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == %{self() => self()}
    end
  end

  @tag timeout: 3000
  test "setze Routingtable" do
    routing_pid = startup()
    new_table = %{routing_pid => routing_pid}
    send routing_pid, {:rout_set_routingtable, self(), new_table}

    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == new_table
    end

  end

  @tag timeout: 3000
  test "kann Routingtable nicht setzten" do
    routing_pid = startup()
    send routing_pid, {:rout_set_routingtable, routing_pid, %{routing_pid => routing_pid}}
    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == %{self() => self()}
    end

  end

  defp startup() do
    selfPID = self()
    routing_pid = spawn(fn ->Routingtable.start_routingtable() end)
    send routing_pid, {:conection_pid, selfPID}
    send routing_pid, {:set_routingtable, %{self() => self()}}
    routing_pid
  end
end
