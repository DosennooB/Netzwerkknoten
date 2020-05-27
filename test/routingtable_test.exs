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
    new_hoptable = %{self() => 1}
    send routing_pid, {:rout_set_routingtable, self(), new_table, new_hoptable}

    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == new_table
    end

  end

  @tag timeout: 3000
  test "kann Routingtable nicht setzten" do
    routing_pid = startup()
    send routing_pid, {:rout_set_routingtable, routing_pid, %{routing_pid => routing_pid}, %{routing_pid => 1}}
    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == %{self() => self()}
    end

  end

  @tag timeout: 3000
  test "sende messages zum Link" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    testantwort = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10, ttl: 63}
    routing_pid = startup()
    send routing_pid, {:rout_message, testm}
    receive do
      {:packet , _sending_link, x} ->
        assert x == testantwort
    end

  end

  #TODO test setting new link for routing table
  #TODO updating link vor Routingtable
  #TODO kill lik for Routing Table
  #TODO set new conection pid
  #TODO test broadcast

  defp startup() do
    selfPID = self()
    routing_pid = spawn(fn ->Routingtable.start_routingtable() end)
    send routing_pid, {:conection_pid, selfPID}
    send routing_pid, {:set_routingtable, self(), %{self() => self()}, %{self() => 1}}
    routing_pid
  end
end
