defmodule Link_VerteilerTest do
  use ExUnit.Case, async: true
  doctest Link_Verteiler


  @tag timeout: 3000
  test "Creat link and sending" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    testantwort = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10, ttl: 63}

    pid = spawn(fn -> Link_Verteiler.start_link_verteiler() end)
    send pid, {:CreateUpdate_link, self(), 10}
    send pid, {:sending, self(), testm}
    receive do
      {:packet , _sending_link, x} ->
        assert x == testantwort
    end
  end

  @tag timeout: 3000
  test "update kosten fuer link" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    testantwort = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10, ttl: 63}

    pid = spawn(fn -> Link_Verteiler.start_link_verteiler() end)
    send pid, {:CreateUpdate_link, self(), 10}
    send pid, {:CreateUpdate_link, self(), 100}
    send pid, {:sending, self(), testm}
    receive do
      {:packet , _sending_link, _x} ->
        assert false
    after
      0_900 ->
        receive do
          {:packet, _sending_link, x} ->
            assert x==testantwort
        end
    end
  end

  @tag timeout: 3000
  test "kill link" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    pid = spawn(fn -> Link_Verteiler.start_link_verteiler() end)
    send  pid, {:CreateUpdate_link, self(), 1}
    send pid, {:sending, self(), testm}
    receive do
      {:packet, sending_link, _value} ->
        send pid, {:kill_link, self()}
        Process.sleep(100)
        assert !Process.alive?(sending_link)
    end

  end

  @tag timeout: 3000
  test "broadcast" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    self_pid = self()
    broadtest1 = spawn(fn -> Link_VerteilerTest.broadcast(self_pid)end)
    broadtest2 = spawn(fn -> Link_VerteilerTest.broadcast(self_pid)end)
    verteiler_pid = spawn(fn -> Link_Verteiler.start_link_verteiler() end)
    send  verteiler_pid, {:CreateUpdate_link, broadtest1, 1}
    send  verteiler_pid, {:CreateUpdate_link, broadtest2, 1}
    send verteiler_pid, {:broadcast, testm}
    receive do
      {:test_ok} ->
        receive do
          {:test_ok} ->
            assert true
        end

    end

  end

  def broadcast(home_pid) do
    receive do
      {:packet , _sending_link, _x} ->
        send home_pid,{:test_ok}
    end

  end
end
