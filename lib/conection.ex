defmodule Conection do
@moduledoc """
Verwaltet die Graphen um die Routingtablle zu be
"""
@type g :: Graph.new()
@type router_pid :: pid
@type routingtable_pid :: pid
  def start_conection() do
    receive do
      {:router_pid, router_pid} ->
        receive do
          {:routingtable_pid, routingtable_pid} ->
            g = Graph.new()
            |> Graph.add_vertex(router_pid)
            |> Graph.add_edge(router_pid, router_pid, weight: 1)
            send routingtable_pid, {:rout_set_routingtable, self(), %{router_pid => router_pid}, %{router_pid => 1}}
            conection(g, router_pid, routingtable_pid)
        end
    end
  end

  defp conection(g, router_pid, routingtable_pid) do
    receive do
      {:con_add_link, m = %Message{}} ->
        ng = newlink(g , m.data, routingtable_pid)
        #Routingtable und Hoptable erstellen
        [routingtable|x] = Pathfinder.new_routingtable(ng, router_pid)
        [hoptb|_r] = x

        send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
        conection(ng, router_pid, routingtable_pid)

      {:con_remove_link, m = %Message{}}  ->
        ng = Graph.delete_edge(g, m.data.v1, m.data.v2)
        |> graphReduzieren(router_pid)
        #Routingtable und Hoptable erstellen
        [routingtable|x] = Pathfinder.new_routingtable(ng, router_pid)
        [hoptb|_r] = x

        send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
        conection(ng, router_pid, routingtable_pid)

      {:con_remove_router, m = %Message{}} ->
        ng = Graph.delete_vertex(g, m.data)
        |> graphReduzieren(router_pid)

        #Routingtable und Hoptable erstellen
        [routingtable|x] = Pathfinder.new_routingtable(ng, router_pid)
        [hoptb|_r] = x

        send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
        conection(ng, router_pid, routingtable_pid)
    end
  end

  @doc """
  fügt dem Graph neue Kanten hinzu und updated die Kanten wenn sie alt sind.
  Wenn eine Kante erstellt wird oder verändert wird, wird ein Broadcast gesendet.
  """
  defp newlink(g = %Graph{}, [e=%Graph.Edge{} | t],routingtable_pid) do
    edgebroadcast = %Message{receiver: routingtable_pid, sender: routingtable_pid, type: :new_link, data: e, size: 4}
    case Graph.edges(g, e.v1, e.v2) do
      [h = %Graph.Edge{}|_t] ->
        cond do
          e.weight != h.weight ->
            send routingtable_pid, {:rout_broadcast, edgebroadcast}
            Graph.update_edge(g, h.v1, h.v2,  weight: e.weight)
            |> newlink( t, routingtable_pid)
          true ->
            newlink(g, t, routingtable_pid)
        end
      [] ->
        send routingtable_pid, {:rout_broadcast, edgebroadcast}
        Graph.add_edge(g, e)
        |> newlink( t, routingtable_pid)
    end
  end

  defp newlink(g = %Graph{}, [], _routingtable_pid) do
    g
  end

  @doc """
  Reduziert den Graph des aktullen Routers auf die Knoten die den
  Router erreichen und vom Router erreicht werden
  """
  defp graphReduzieren(g, router_pid) do
    vreacheble = Graph.reachable(g, router_pid)
    vreaching = Graph.reaching(g, router_pid)
    vertexnew = Enum.uniq(vreacheble ++vreaching)
    vertexdel = Graph.vertices(g) -- vertexnew
    Graph.delete_vertices(g, vertexdel)
  end
end
