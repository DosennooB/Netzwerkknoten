defmodule Link_pidTest do
  use ExUnit.Case, async: true
  doctest Link_pid

  @tag timeout: 10000
  test "Link sendet message" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 10) end)
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    send(pid, {:sending, testm})

    receive do
      {:packet, x, m} ->
        assert x == pid
        assert m == %{testm | ttl: testm.ttl - 1}
    end
  end

  @tag timeout: 3000
  test "Link keine Message ttl überschritten" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 10) end)

    testm = %Message{
      receiver: self(),
      sender: self(),
      type: "test",
      data: "hello",
      size: 10,
      ttl: 1
    }

    send(pid, {:sending, testm})

    receive do
      {:packet, _x, _m} ->
        assert false
    after
      0_500 -> assert true
    end
  end

  @tag timeout: 3000
  test "updating link kosten" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 10) end)
    send(pid, {:updating_kost, 1})
    send(pid, {:get_kost, self()})

    receive do
      {:kosten, _star, _ziel, value} ->
        assert value == 1
    end
  end

  @tag timeout: 3000
  test "kill funktioniert" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 10) end)
    send(pid, {:kill, pid})
    Process.sleep(100)
    assert !Process.alive?(pid)
  end

  @tag timeout: 3000
  test "kill bei falscher pid" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 10) end)
    send(pid, {:kill, self_pid})
    Process.sleep(100)
    assert Process.alive?(pid)
  end
end
