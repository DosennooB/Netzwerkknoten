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
  #TODO test schreiben
  @tag timeout: 3000
  test "Link shutdown" do
    self_pid = self()
    pid = spawn(fn -> Link_pid.start_link(self_pid, 3) end)
    delrouter = %Message{
      receiver: self(),
      sender: self(),
      type: :del_router,
      data: self(),
      size: 2
    }
    Process.sleep(200)
    Process.exit(pid, :router_shutdown)
    receive do
      {:packet, _self, msg} ->
        assert msg == delrouter
    end
    assert not Process.alive?(pid)
  end

  @tag timeout: 3000
  test "Router shutdown" do
    self_pid = self()
    pid1 = spawn(fn -> Link_pid.start_link(self_pid, 3) end)
    pid2 = spawn(fn -> Process.link(pid1)
    Process.sleep(3000)
    end)

    delrouter = %Message{
      receiver: pid2,
      sender: pid2,
      type: :del_router,
      data: pid2,
      size: 2
    }
    Process.sleep(200)
    Process.exit(pid2, :router_shutdown)
    receive do
      {:packet, _self, msg} ->
        assert msg == delrouter
    end
    assert not Process.alive?(pid2)
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
