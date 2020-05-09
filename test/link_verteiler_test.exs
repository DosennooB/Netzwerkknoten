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
  #TODO Test Broadcast
  defp broadcast(home_pid) do
    receive do
      {:packet , sending_link, x} ->
        # code
    end

  end
end
