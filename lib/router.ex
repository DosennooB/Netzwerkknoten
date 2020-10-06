defmodule Router do
  def startrouter() do
    self_pid = self()
    routetbl_pid = spawn_link(fn -> Routingtable.start_routingtable() end)
    con_pid = spawn_link(fn -> Conection.start_conection() end)

    send con_pid, {:router_pid, self_pid}
    send con_pid, {:routingtable_pid, routetbl_pid}

    send routetbl_pid, {:conection_pid, con_pid}
    router(con_pid, routetbl_pid)
  end

  defp router(con_pid, routetbl_pid) do
    receive do
      {:packet, _x, msg = %Message{}} ->
        cond do
          msg.receiver == self() and  msg.type == :message ->
            send :perant, {:message_recived, msg}


          msg.type == :message and msg.ttl > 0 ->
            send routetbl_pid, {:rout_message, msg}

          msg.type == :message and msg.ttl <= 0 ->
            ttl = %Message{
              receiver: msg.sender,
              sender: self(),
              type: :ttl_expired,
              data: msg.data,
              size: msg.size
            }
            send routetbl_pid,  {:rout_message, ttl}

          msg.type == :ttl_expired and msg.ttl > 0 ->
            send routetbl_pid, {:rout_message, msg}

          msg.type == :new_link and msg.ttl > 0 ->
            send con_pid, {:con_add_link, msg}

          msg.type == :del_router ->
            cond do
              msg.data == self() ->
                send :perant, {:router_shutdown, self()}
                exit(:router_shutdown)
              msg.data != self() ->
                send con_pid, {:con_remove_router, msg}
            end

          msg.type == :del_link and msg.ttl > 0 ->
            send con_pid, {:con_remove_link, msg}

          true ->
            IO.inspect(msg)
        end
        router(con_pid, routetbl_pid)
    end
    IO.puts("Router beendet sich")
  end

end
