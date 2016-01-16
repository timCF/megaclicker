defmodule Megaclicker do
	use Silverb, [
		{"@pg2_group", :clients},
	]
	use Application
	require Exutils

	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		_ = :pg2.create(@pg2_group)

		spawn_link(fn ->
			:timer.sleep(1000)
			try do
				args = %{ttl: ttl, threads: threads} = parse_args(System.argv)
				case run_childs(args) |> Exutils.try_catch do
					:ok -> :timer.sleep(ttl * 1000)
					error -> IO.puts("HALT, ERROR ON START THREADS #{inspect error}")
				end
				terminate_childs(threads)
			catch
				error -> IO.puts("HALT, RUNTIME ERROR #{inspect error}")
			rescue
				error -> IO.puts("HALT, RUNTIME ERROR #{inspect error}")
			end
			:erlang.halt
		end)

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Megaclicker.Supervisor]
		Supervisor.start_link([], opts)
	end

	def range(stop, stop), do: stop
	def range(start, stop) when (stop > start), do: (:random.uniform(stop - (start-1)) + (start-1))

	defp parse_args([_|raw]) do
		{args, [], []} = OptionParser.parse(raw)
		parsed = %{url: url, x_res: x_res, x_from: x_from, x_to: x_to, y_res: y_res, y_from: y_from, y_to: y_to, threads: threads, ttl: ttl} = Enum.reduce(args, %{}, fn({k,v},acc) -> Map.put(acc, k, Maybe.to_integer(v)) end)
		if not(	is_binary(url) and
				(Map.delete(parsed, :url) |> Map.values |> Enum.all?(&(is_integer(&1) and (&1 >= 0)))) and
				(x_res >= x_to) and
				(x_to >= x_from) and
				(y_res >= y_to) and
				(y_to >= y_from) and
				(threads > 0) and
				(ttl > 0)), do: raise("got some wrong input params")
		parsed
	end

	defp run_childs(args) do
		#
		#	TODO
		#
		#children = Enum.map(1..2, fn(n) ->
		#	this_id = String.to_atom("session_#{n}")
		#	worker(Megaclicker.Worker, [%{	config: %WebDriver.Config{name: String.to_atom("browser_#{n}"), browser: :chrome},
		#									session: this_id,
		#									url: "http://another_cafe.inbet.cc/slots/bets_poker3x?fun"}], [id: this_id]) end)
		:ok
	end

	defp terminate_childs(threads) do
		#
		#	TODO
		#
	end

end
