defmodule Megaclicker do
	use Silverb, [
		{"@pg2_group", :clients},
		{"@elem_types", ["class","css","id","name","link","partial_link","tag","xpath"]}
	]
	use Application
	require Exutils

	defstruct	config: nil,
				session: nil,
				url: nil,
				x_res: nil,
				x_from: nil,
				x_to: nil,
				y_res: nil,
				y_from: nil,
				y_to: nil,
				elem_val: nil, # get this on runtime
				elem_type: nil,
				elem_selector: nil,
				mode: nil, # :page | :elem
				ttl: nil,
				threads: nil
	#
	# public
	#


	def range(stop, stop), do: stop
	def range(start, stop) when (stop > start), do: (:random.uniform(stop - (start-1)) + (start-1))


	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		_ = :pg2.create(@pg2_group)
		_ = File.mkdir("./screenshots")

		spawn_link(fn ->
			:timer.sleep(1000)
			try do
				args = %Megaclicker{ttl: ttl} = parse_args(System.argv)
				case run_childs(args) |> Exutils.try_catch do
					:ok -> :timer.sleep(ttl * 1000)
					error -> IO.puts("HALT, ERROR ON START THREADS #{inspect error}")
				end
			catch
				error -> IO.puts("HALT, RUNTIME ERROR #{inspect error}")
			rescue
				error -> IO.puts("HALT, RUNTIME ERROR #{inspect error}")
			end
			terminate_childs()
			:erlang.halt
		end)

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Megaclicker.Supervisor]
		Supervisor.start_link([], opts)
	end
	def stop(reason) do
		IO.puts("ERROR, terminate because of reason #{inspect reason}")
		terminate_childs()
		:erlang.halt
	end


	#
	#	priv
	#


	defp parse_args([_|raw]) do
		{args, [], []} = OptionParser.parse(raw)
		Enum.reduce(args, %{}, fn({k,v},acc) -> Map.put(acc, k, Maybe.to_integer(v)) end)
		|> parse_args_proc
	end
	defp parse_args_proc(parsed = %{url: url, x_res: x_res, x_from: x_from, x_to: x_to, y_res: y_res, y_from: y_from, y_to: y_to, threads: threads, ttl: ttl}) do
		if not(	is_binary(url) and
				(Map.delete(parsed, :url) |> Map.values |> Enum.all?(&(is_integer(&1) and (&1 >= 0)))) and
				(x_res >= x_to) and
				(x_to >= x_from) and
				(y_res >= y_to) and
				(y_to >= y_from) and
				(threads > 0) and
				(ttl > 0)), do: raise("got some wrong input params #{inspect parsed}")
		%Megaclicker{url: url, x_res: x_res, x_from: x_from, x_to: x_to, y_res: y_res, y_from: y_from, y_to: y_to, threads: threads, ttl: ttl, elem_type: :tag, elem_selector: "body", mode: :page}
	end
	defp parse_args_proc(%{url: url, threads: threads, ttl: ttl, elem_type: elem_type, elem_selector: elem_selector})
			when (is_binary(url) and is_integer(threads) and (threads > 0) and is_integer(ttl) and (ttl > 0) and (elem_type in @elem_types) and is_binary(elem_selector)) do
		%Megaclicker{url: url, threads: threads, ttl: ttl, elem_type: String.to_atom(elem_type), elem_selector: elem_selector, mode: :elem}
	end
	defp parse_args_proc(parsed), do: raise("unexpected params #{inspect parsed}")


	defp run_childs(args = %Megaclicker{threads: threads}) do
		Enum.each(1..threads, fn(n) ->
			this_id = String.to_atom("session_#{n}")
			:ok = :supervisor.start_child(Megaclicker.Supervisor, Supervisor.Spec.worker(Megaclicker.Worker, [%Megaclicker{args | config: %WebDriver.Config{name: String.to_atom("browser_#{n}"), browser: :chrome}, session: this_id}], [restart: :transient, id: this_id])) |> elem(0)
		end)
	end


	defp terminate_childs do
		case 	:pg2.get_members(@pg2_group)
				|> Stream.map(fn(thread) -> GenServer.call(thread, :force_exit, 60000) end)
				|> Enum.filter(&(&1 != :ok)) do
			[] -> :ok
			some -> IO.puts("ERROR while terminate workers #{inspect some}")
		end
		Enum.each(1..5, fn(_) ->
			WebDriver.stop_all_browsers() |> Exutils.try_catch
			:timer.sleep(100)
		end)
	end


end
