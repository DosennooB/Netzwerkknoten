defmodule Benchmark do
  def make_ring(list, 0) do
    x = List.first(list)
    y = List.last(list)

    nlink = %Message{
      receiver: self(),
      sender: x,
      type: :new_link,
      data: [%Graph.Edge{v1: y, v2: x, weight: 0}],
      size: 4
    }
    send y, {:packet, self(), nlink}
    list
  end

  def make_ring(list, conter) do
    pid = spawn(fn -> Router.startrouter() end)
    nlink = %Message{
      receiver: self(),
      sender: List.first(list),
      type: :new_link,
      data: [%Graph.Edge{v1: pid, v2: List.first(list), weight: 0}],
      size: 4
    }
    send pid, {:packet, self(), nlink}

    list1 = [pid| list]
    IO.puts(conter)
    make_ring(list1, conter-1)
  end

  def make_n_links(_list, 0) do
    nil
  end
  def make_n_links(list, n_dimension) do
    Enum.map(list, fn x ->
      y = Enum.random(list)
      nlink = %Message{
        receiver: self(),
        sender: self(),
        type: :new_link,
        data: [%Graph.Edge{v1: x, v2: y, weight: 0}],
        size: 4
      }
      send x, {:packet, self(), nlink}
    end)

    make_n_links(list, n_dimension-1)
  end
  def send_all_to_all(list) do
    Enum.map(list, fn x ->
      Enum.map(list, fn y ->
        nm = %Message{
          receiver: y,
          sender: x,
          type: :message,
          data: "Nachricht von  zu ",
          size: 0,
          ttl: 10000
        }
        send x , {:packet,self(), nm}
      end)
    end)
  end
  def recive_all(list) do
     x = Enum.count(list)
     recive_all(x*x,x*x)
  end
  def recive_all(0, _all) do
    IO.puts("Alle angekommen")
  end
  def recive_all(counter, all) do
    receive do
      {:message_recived, _value} ->
        #IO.puts("receive #{counter} : #{all}")
    end
    recive_all(counter - 1, all)

  end
  def kill_routers(list) do
    Enum.map(list, fn x ->
      msg = %Message{
        receiver: self(),
        sender: self(),
        type: :del_router,
        data: x,
        size: 3
      }
      send x, {:packet, self(), msg}
    end)
  end
  def wait_for_kill([]) do
    :ok
  end

  def wait_for_kill(list) do
    receive do
      {:router_shutdown, pid} ->
        List.delete(list, pid)
        |>wait_for_kill()
    end
  end


end
Process.register(self(), :perant)
pid = spawn(fn -> Router.startrouter() end)
list = Benchmark.make_ring([pid], 100)
Benchmark.send_all_to_all(list)
Benchmark.recive_all(list)
Benchmark.kill_routers(list)
Benchmark.wait_for_kill(list)
IO.puts("hallo")
