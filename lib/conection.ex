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
        ng = newlink(g , m.data, routingtable_pid, router_pid)
        #Routingtable und Hoptable erstellen
        {routingtable,hoptb} = Pathfinder.new_routingtable(ng, router_pid)


        send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
        conection(ng, router_pid, routingtable_pid)

      {:con_remove_link, m = %Message{}}  ->
        case Graph.edges(g, m.data.v1, m.data.v2) do
          [h = %Graph.Edge{}|_t] ->
            if h.v1 == router_pid and h.v2 == router_pid do
              conection(g, router_pid, routingtable_pid)
            else
              ng = Graph.delete_edge(g, m.data.v1, m.data.v2)
              |> graphReduzieren(router_pid)
              #Routingtable und Hoptable erstellen
              {routingtable,hoptb} = Pathfinder.new_routingtable(ng, router_pid)
              send routingtable_pid, {:rout_broadcast, m}
              send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
              conection(ng, router_pid, routingtable_pid)
            end
          [] ->
            conection(g, router_pid, routingtable_pid)
        end

      {:con_remove_router, m = %Message{}} ->
        if m.data == router_pid do
          conection(g, router_pid, routingtable_pid)
        else
          ng = Graph.delete_vertex(g, m.data)
          |> graphReduzieren(router_pid)
          #Routingtable und Hoptable erstellen
          send routingtable_pid, {:rout_broadcast, m}
          {routingtable,hoptb} = Pathfinder.new_routingtable(ng, router_pid)
          send routingtable_pid, {:rout_set_routingtable, self(), routingtable, hoptb}
          conection(ng, router_pid, routingtable_pid)
        end

      {:rout_alledges, alledges = %Message{}} ->
        send routingtable_pid, {:rout_message, alledges}
        conection(g, router_pid, routingtable_pid)
    end
  end

  @spec newlink(Graph.t(), [Graph.Edge.t()], any, any) :: Graph.t()
  @doc """
  fügt dem Graph neue Kanten hinzu und updated die Kanten wenn sie alt sind.
  Wenn eine Kante erstellt wird oder verändert wird, wird ein Broadcast gesendet.
  """
  def newlink(g = %Graph{}, [e=%Graph.Edge{} | t], routingtable_pid, router_pid) do
    edgebroadcast = %Message{receiver: routingtable_pid, sender: routingtable_pid, type: :new_link, data: [e], size: 0}
    case Graph.edges(g, e.v1, e.v2) do
      [h = %Graph.Edge{}|_t] ->
        cond do
          e.weight != h.weight ->
            send routingtable_pid, {:rout_broadcast, edgebroadcast}
            Graph.update_edge(g, h.v1, h.v2,  weight: e.weight)
            |> newlink( t, routingtable_pid, router_pid)
          true ->
            newlink(g, t, routingtable_pid, router_pid)
        end

      [] ->
        send routingtable_pid, {:rout_broadcast, edgebroadcast}
        ng = Graph.add_edge(g, e)
        #wenn es eine aus gehenden Kannte ist wird dem nachtbarn der komplette graph geschickt

        case e.v1 == router_pid do
          true ->
            ae = Graph.edges(ng)
            alledge = %Message{receiver: e.v2, sender: router_pid, type: :new_link, data: ae, size: 0}
            send self(), {:rout_alledges, alledge}
          false ->
            nil
        end
        newlink(ng , t ,routingtable_pid, router_pid)
    end
  end

  def newlink(g = %Graph{}, [], _routingtable_pid, _router_pid) do
    g
  end

  @doc """
  Reduziert den Graph des aktullen Routers auf die Knoten die den
  Router erreichen und vom Router erreicht werden
  """
  def graphReduzieren(g, router_pid) do
    vreacheble = Graph.reachable(g, [router_pid])
    vreaching = Graph.reaching(g, [router_pid])
    vertexnew = Enum.uniq(vreacheble ++vreaching)
    vertexdel = Graph.vertices(g) -- vertexnew
    Graph.delete_vertices(g, vertexdel)
  end
end
