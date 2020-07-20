defmodule RouterTest do
  use ExUnit.Case, async: true
  doctest Router

test "test" do
  pid = spawn(fn -> Router.startrouter() end)

  list = make_ring([pid], 10)

  nm = %Message{
    receiver: pid,
    sender: List.first(list),
    type: :message,
    data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 3}],
    size: 4
  }
  send List.first(list), {:packet, nm}

  Process.sleep(1000)
end



  def make_ring(list, conter) do
    pid = spawn(fn -> Router.startrouter() end)

    nlink = %Message{
      receiver: self(),
      sender: List.first(list),
      type: :new_link,
      data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 3}],
      size: 4
    }
    send pid, {:packet, nlink}

    list1 = [pid| list]
    if conter > 0 do
      IO.puts(conter)
      make_ring(list1, conter-1)
    else
      list1
    end
  end
end
