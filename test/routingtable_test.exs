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

  @tag timeout: 3000
  test "sende broadcast message" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    testantwort = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10, ttl: 63}
    routing_pid = startup()
    send routing_pid, {:rout_broadcast, testm}
    receive do
      {:packet , _sending_link, x} ->
        assert x == testantwort
    end
  end

  @tag timeout: 3000
  test "neuer Link in Routingtable ein gefügt und erstellt" do
    self_pid = self()
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    routing_pid = startup()
    send routing_pid, {:rout_message, testm}
    receive do
      {:packet , alter_link, _x} ->

        assert alter_link != self()

        umleiten_pid = spawn(fn ->Routingtable_test.umleiten(self_pid) end)
        testum = %Message{receiver: umleiten_pid, sender: self(), type: "test", data: "hello", size: 10}
        send routing_pid, {:rout_set_routingtable, self(), %{umleiten_pid => umleiten_pid}, %{umleiten_pid => 2}}
        send routing_pid, {:rout_message, testum}
        receive do
          {:packet , sending_link, _x} ->
            assert alter_link != sending_link
        end
    end
  end

  @tag timeout: 3000
  test "kill Link in Routingtable" do
    self_pid = self()
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    routing_pid = startup()
    send routing_pid, {:rout_message, testm}
    receive do
      {:packet , alter_link, _x} ->
        umleiten_pid = spawn(fn ->Routingtable_test.umleiten(self_pid) end)
        send routing_pid, {:rout_set_routingtable, self(), %{umleiten_pid => umleiten_pid}, %{umleiten_pid => 2}}
        Process.sleep(200)
        assert !Process.alive?(alter_link)
    end
  end



  @tag timeout: 3000
  test "setzte neue Connection_pid" do
    routing_pid = startup()
    send routing_pid, {:conection_pid, routing_pid}
    send routing_pid, {:rout_set_routingtable, self(), %{routing_pid => routing_pid}, %{routing_pid => 1}}
    send routing_pid, {:rout_get_routingtable, self()}
    receive do
      {:rout_routingtable, value} ->
        assert value == %{self() => self()}
    end

  end


  @tag timeout: 3000
  test "Update Link kosten beim setzten von Routintable" do
    testm = %Message{receiver: self(), sender: self(), type: "test", data: "hello", size: 10}
    routing_pid = startup()
    send routing_pid, {:rout_message, testm}
    receive do
      {:packet , _send_link, _x} ->
        send routing_pid, {:rout_set_routingtable, self(), %{self() => self()}, %{self() => 20}}
        send routing_pid, {:rout_message, testm}
        receive do
          {:packet, _send_link, _x} ->
            assert false
          after
            0_150 ->
              receive do
                {:packet, _send_link, _x} ->
                  assert true
              end

        end

      after
        0_300 ->
          assert false
    end

  end


  defp startup() do
    selfPID = self()
    routing_pid = spawn(fn ->Routingtable.start_routingtable() end)
    send routing_pid, {:conection_pid, selfPID}
    send routing_pid, {:set_routingtable, self(), %{self() => self()}, %{self() => 1}}
    routing_pid
  end

  def umleiten(pid) do
    receive do
      {:packet, sending_link, x} ->
        send pid, {:packet, sending_link, x}
    end
  end
end
