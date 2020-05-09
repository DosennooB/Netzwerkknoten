defmodule Router do
  def startrouter() do
    router(%{}, %{})
  end

  defp router(routingtable, links) do
    receive do
      {:new_link, link_kosten, knoten_pid} ->
        cond do
          link_kosten > 0 ->
            new_links = neuenLinkAnlegen(links, knoten_pid, link_kosten)
            new_routingtable = neuenLinkInRoutingtable(routingtable, knoten_pid, link_kosten)
            router(new_routingtable, new_links)

          true ->
            router(routingtable, links)
        end

      {:get_kosten_zu_link, link_pid, rueck_pid} ->
        send(rueck_pid, {:kosten_zu_link, Map.get(links, link_pid), link_pid, self()})
        router(routingtable, links)

      {:get_kosten_zu_ziel, ziel_pid, rueck_pid} ->
        send(
          rueck_pid,
          {:kosten_zu_ziel, Map.get(routingtable, ziel_pid)[:kosten], ziel_pid, self()}
        )

        router(routingtable, links)
    end
  end

  def neuenLinkAnlegen(links, knoten_pid, link_kosten) do
    Map.put(links, knoten_pid, link_kosten)
  end

  def neuenLinkInRoutingtable(routingtable, ziel_pid, link_kosten) do
    cond do
      !Map.has_key?(routingtable, ziel_pid) ->
        Map.put(routingtable, ziel_pid, kosten: link_kosten, hop: ziel_pid)

      Map.get(routingtable, ziel_pid)[:hop] == ziel_pid ->
        put_in(routingtable[ziel_pid][:kosten], link_kosten)

      Map.get(routingtable, ziel_pid)[:kosten] > link_kosten ->
        Map.put(routingtable, ziel_pid, kosten: link_kosten, hop: ziel_pid)

      true ->
        routingtable
    end
  end
end
