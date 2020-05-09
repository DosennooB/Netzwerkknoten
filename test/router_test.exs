defmodule RouterTest do
  use ExUnit.Case, async: true
  doctest Router

  @tag timeout: 1000
  test "Link in Linktable gespeichert" do
    pid = spawn(fn -> Router.startrouter() end)
    send(pid, {:new_link, 10, self()})
    send(pid, {:get_kosten_zu_link, self(), self()})

    receive do
      {:kosten_zu_link, value, _link_pid, _pid} ->
        assert value == 10
    end
  end

  @tag timeout: 1000
  test "Link mit geänderten kosten in Linktabelle speichern" do
    pid = spawn(fn -> Router.startrouter() end)
    send(pid, {:new_link, 10, self()})
    send(pid, {:get_kosten_zu_link, self(), self()})

    receive do
      {:kosten_zu_link, value, _link_pid, _pid} ->
        assert value == 10
    end

    send(pid, {:new_link, 8, self()})
    send(pid, {:get_kosten_zu_link, self(), self()})

    receive do
      {:kosten_zu_link, value, _link_pid, _pid} ->
        assert value == 8
    end
  end

  @tag timeout: 1000
  test "Keine negativen Linkkosten" do
    pid = spawn(fn -> Router.startrouter() end)
    send(pid, {:new_link, 10, self()})
    send(pid, {:new_link, -1, self()})
    send(pid, {:get_kosten_zu_link, self(), self()})

    receive do
      {:kosten_zu_link, value, _link_pid, _pid} ->
        assert value == 10
    end
  end
end
