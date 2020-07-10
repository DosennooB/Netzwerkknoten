defmodule PathfinderTest do
  use ExUnit.Case, async: true
  doctest Pathfinder

  @tag timeout: 1000
  test "grund funktionalität" do
    g = Graph.new()
    |> Graph.add_edge( self(), self())
    |> Graph.add_edge( self(), :v2 )
    |> Graph.add_edge( self(),:v3)
    {e,j} = Pathfinder.new_routingtable(g, self())
    assert Map.get(e,self()) == self()
    assert Map.get(e,:v2) == :v2
    assert Map.get(e,:v3) == :v3
    assert Map.get(j, self()) == 1
    assert Map.get(j, :v2) == 1
    assert Map.get(j, :v3) == 1
  end

   @tag timeout: 1000
   test "Test Kanten Gewichte" do
     g = Graph.new()
     |>Graph.add_edge(self(),self(), weight: 3)
     {_e,j} = Pathfinder.new_routingtable(g, self())
     assert Map.get(j, self()) == 3
   end


   @tag timeout: 1000
   test "nehme günstigstigste Route" do
     g = Graph.new()
     |>Graph.add_edge(self(), self())
     |>Graph.add_edge(self(), :v1, weight: 3)
     |>Graph.add_edge(self(), :v2, weight: 10)
     |>Graph.add_edge(:v1, :v2, weight: 2)
     {e,_j} = Pathfinder.new_routingtable(g, self())
     assert Map.get(e, :v2) == :v1
   end

end
