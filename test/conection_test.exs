defmodule ConectionTest do
  use ExUnit.Case, async: true
  doctest Conection

@tag timeout: 1000
test "Füge Link hinzu" do
  con_pid = startup()
  assert true
end

def startup() do
  selfPID = self()
  conection_pid = spawn(fn ->Conection.start_conection() end)
  send conection_pid, {:router_pid, selfPID}
  send conection_pid, {:routingtable_pid, selfPID}
  conection_pid
end
end
