defmodule Pathfinder do
  @moduledoc """
  Erzeugt aus den Graph Netztwerk die Wege die Optimalen Wege für ein Paket zu finden.
  Der routingtable besteht aus %{zielrouter, hopp}
  hoptb besteht aus %{hopp, kosten}
  """
  @type routingtable :: map()
  @type hoptb :: map()
  @type startpoint :: pid
  def new_routingtable(g = %Graph{}, startpoint) do
    reach = Graph.reachable(g, startpoint)
    #Hopptable generierung
    hoptb = Map.new()
    Graph.out_edges(g, startpoint)
    |> Enum.each( fn x = %Graph.Edge{} -> Map.put(hoptb, x.v2, x.weight) end)
    new_routingtable(g, startpoint, %{}, hoptb, reach)
  end
  def new_routingtable(g = %Graph{}, startpoint, routingtable = %{}, hoptb, [h|t]) do
    path = Graph.dijkstra(g, startpoint, h)
    |> List.delete_at(0)
    [hopp|_c] = path
    Enum.each(path, fn x -> Map.put_new(routingtable, x, hopp) end)
    new_routingtable(g, startpoint, routingtable, hoptb, t -- path)
  end
  def new_routingtable(_g = %Graph{}, _startpoint, routingtable, hoptb, []) do
    [routingtable,hoptb]
  end
end
