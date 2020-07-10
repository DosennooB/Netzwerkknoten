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

@tag timeout: 3000
test "neuer link eingehend" do
  selfPID = self()
  con_pid = startup(selfPID)
  nPID = spawn(fn -> ConectionTest.umleiten(selfPID) end)
  #Die erste Nachricht durch startup
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  e = %Graph.Edge{v1: nPID, v2: selfPID, weight: 3}
  nlink = %Message{receiver: self(), sender: self(), type: :new_link, data: [e], size: 4}
  send con_pid, {:con_add_link, nlink}

  #erster broadcast
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

@tag timeout: 3000
test "neuerlink ausgehend" do
  selfPID = self()
  con_pid = startup(selfPID)
  nPID = spawn(fn -> ConectionTest.umleiten(selfPID) end)
  #Die erste Nachricht durch startup
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  #neuer Link wird angelegt
  e = %Graph.Edge{v1: selfPID, v2: nPID, weight: 3}
  nlink = %Message{receiver: self(), sender: self(), type: :new_link, data: [e], size: 4}
  send con_pid, {:con_add_link, nlink}

  receive do
    {:rout_broadcast, value = %Message{}} ->
      assert value.data == e
  end

  #dem neuen Link werden alle edges geschickt
  receive do
    {:rout_broadcast, value = %Message{}} ->
      edges = value.data
      assert Enum.member?(edges, e)
      def = %Graph.Edge{v1: selfPID, v2: selfPID}
      assert Enum.member?(edges, def)
  end
  receive do
    {:rout_set_routingtable, ^con_pid, routingtable, hoptb} ->
      assert selfPID == Map.get(routingtable, selfPID)
      assert nPID == Map.get(routingtable, nPID)
      assert 1 == Map.get(hoptb, selfPID)
      assert 3 == Map.get(hoptb, nPID)
  end
end
@tag timeout: 3000
test "ausgehend link 2 generation" do
  selfPID = self()
  con_pid = startup(selfPID)
  nPID1 = spawn(fn -> ConectionTest.umleiten(selfPID) end)
  nPID2 = spawn(fn -> ConectionTest.umleiten(selfPID) end)
  #Die erste Nachricht durch startup
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  #vorbereiten auf neuen Link
  e1 = %Graph.Edge{v1: selfPID, v2: nPID1, weight: 3}
  e2 = %Graph.Edge{v1: nPID1, v2: nPID2, weight: 3}
  nlink1 = %Message{receiver: self(), sender: self(), type: :new_link, data: [e1], size: 4}
  nlink2 = %Message{receiver: self(), sender: self(), type: :new_link, data: [e2], size: 4}

   #erster Link wird angelegt
  send con_pid, {:con_add_link, nlink1}

  #Nach ersten link alle nachrichten einfangen
  receive do
    {:rout_broadcast, _value = %Message{}} ->
      nil
  end
  receive do
    {:rout_broadcast, _value = %Message{}} ->
      nil
  end
  receive do
    {:rout_set_routingtable, ^con_pid, _routingtable, _hoptb} ->
      nil
  end

  #zweiter link
  send con_pid, {:con_add_link, nlink2}
  receive do
    {:rout_broadcast, value = %Message{}} ->
      assert value.data == e2
  end
  receive do
    {:rout_set_routingtable, ^con_pid, routingtable, hoptb} ->
      assert selfPID == Map.get(routingtable, selfPID)
      assert nPID1 == Map.get(routingtable, nPID1)
      assert nPID1 == Map.get(routingtable, nPID2)
      assert 1 == Map.get(hoptb, selfPID)
      assert 3 == Map.get(hoptb, nPID1)
  end
end

@tag timeout: 3000
test "meherer edges geleichzeitig hinzu fügen" do

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