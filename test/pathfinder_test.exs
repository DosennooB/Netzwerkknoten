defmodule PathfinderTest do
  use ExUnit.Case, async: true
  doctest Pathfinder

  @tag timeout: 1000
  test "grund funktionalität" do
    g = Graph.new()
    |> Graph.add_edge( self(), self())
    |> Graph.add_edge( self(), :v2 )
    |> Graph.add_edge( :v2,:v3)
    e = Pathfinder.new_routingtable(g, self())
    assert true
  end

end
