defmodule RouterTest do
  use ExUnit.Case, async: true
  doctest Router

  @tag timeout: 3000
  test "test" do
    Process.register(self(), :perant)
    pid = spawn(fn -> Router.startrouter() end)

    list =RouterTest.make_ring([pid], 10)

    nlink = %Message{
      receiver: self(),
      sender: self(),
      type: :new_link,
      data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 0}],
      size: 4
    }
    send pid, {:packet, self(), nlink}

    nm = %Message{
      receiver: pid,
      sender: List.first(list),
      type: :message,
      data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 3}],
      size: 0,
      ttl: 10000
    }

    send List.first(list), {:packet,self(), nm}
    receive do
      {:message_recived, _msg} ->
        :ok
    end
  end


  def make_ring(list, conter) do
    pid = spawn_link(fn -> Router.startrouter() end)
    nlink = %Message{
      receiver: self(),
      sender: List.first(list),
      type: :new_link,
      data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 0}],
      size: 4
    }
    send pid, {:packet, self(), nlink}

    nlink1 = %Message{
      receiver: self(),
      sender: self(),
      type: :new_link,
      data: [%Graph.Edge{v1: pid, v2: Enum.random(list), weight: 0}],
      size: 4
    }
    send pid, {:packet, self(), nlink1}

    list1 = [pid| list]
    if conter > 0 do
      make_ring(list1, conter-1)
    else
      list1
    end
  end
end
