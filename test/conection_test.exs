defmodule ConectionTest do
  use ExUnit.Case, async: true
  doctest Conection

@tag timeout: 1000
test "Füge Link auserhalb des Graphen hinzu" do
  selfPID = self()
  con_pid = startup(selfPID)
  e = %Graph.Edge{v1: :v1, v2: :v2}
  nlink = %Message{receiver: self(), sender: self(), type: :new_link, data: [e], size: 4}
  send con_pid, {:con_add_link, nlink}
  #Die erste Nachricht durch startup
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  receive do
    {:rout_broadcast, value = %Message{}} ->
      assert value.data == e
  end

  receive do
    {:rout_set_routingtable, ^con_pid, routingtable, hoptb} ->
      assert %{selfPID => selfPID} == routingtable
      assert %{selfPID => 1} == hoptb
  end
end

@tag timeout: 1000
test "update Link" do
  selfPID = self()
  con_pid = startup(selfPID)
  e = %Graph.Edge{v1: selfPID, v2: selfPID, weight: 3}
  uplink = %Message{receiver: self(), sender: self(), type: :new_link, data: [e], size: 4}
  send con_pid, {:con_add_link, uplink}
  #Die erste Nachricht durch startup
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  receive do
    {:rout_broadcast, value = %Message{}} ->
      assert value.data == e
  end

  receive do
    {:rout_set_routingtable, ^con_pid, routingtable, hoptb} ->
      assert %{selfPID => selfPID} == routingtable
      assert %{selfPID => 3} == hoptb
  end
end

def startup(selfPID) do
  conection_pid = spawn(fn ->Conection.start_conection() end)
  send conection_pid, {:router_pid, selfPID}
  send conection_pid, {:routingtable_pid, selfPID}
  conection_pid
end
#um einen anderen Prozess zu generieren
def umleiten(selfPID) do
  receive do
    {x, value} ->
      send selfPID , {x, value}
  end
end
end
