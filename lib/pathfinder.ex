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
    reach = Graph.reachable(g, [startpoint])
    edges = Graph.out_edges(g, startpoint)

    hoptb = make_hoptable(Map.new(), edges)

    new_routingtable(g, startpoint, Map.new(), hoptb, reach)
  end


  def new_routingtable(g = %Graph{}, startpoint, routingtable , hoptb, [h|t]) do
    path = Graph.dijkstra(g, startpoint, h)
    |> List.delete_at(0)
    [hopp|_c] = path
    rtn = add_to_routingtable(routingtable, path, hopp)
    new_routingtable(g, startpoint, rtn, hoptb, t -- path)
  end
  def new_routingtable(_g = %Graph{}, _startpoint, routingtable, hoptb, []) do
    {routingtable,hoptb}
  end

  def add_to_routingtable(routingtable, [h|t], hopp) do
    add_to_routingtable(Map.put(routingtable,h,hopp),t, hopp)
  end

  def add_to_routingtable(routingtable,[], _hopp) do
    routingtable
  end

  def make_hoptable(hoptb, [ h = %Graph.Edge{} |t]) when is_map(hoptb) do
    make_hoptable(Map.put(hoptb, h.v2, h.weight), t)
  end

  def make_hoptable(hoptb, []) when is_map(hoptb) do
    hoptb
  end

end
