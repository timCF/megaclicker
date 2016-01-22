defmodule Megaclicker.Worker do
	use Silverb, [
		{"@pg2_group", :clients},
		{"@ttl", 1}
	]
	use GenServer
	require Exutils

	#
	#	priv
	#

	defmacrop retry(body) do
		quote location: :keep do
			Exutils.retry(fn() -> unquote(body) |> Exutils.try_catch end, &pred/1, 10, 500)
		end
	end
	defp pred(%{width: x, height: y}), do: (is_number(x) and (x >= 0) and is_number(y) and (y >= 0))
	defp pred(:ok), do: true
	defp pred(some) when is_tuple(some), do: (elem(some,0) == :ok)
	defp pred(_), do: false

	#
	#	public
	#

	def start_link(args), do: GenServer.start_link(__MODULE__, args)
	def init(args = %Megaclicker{config: config = %WebDriver.Config{name: browser}, session: session, url: url, x_res: x_res, y_res: y_res, mode: mode, elem_type: elem_type, elem_selector: elem_selector}) do
		<<a::32,b::32,c::32>> = :crypto.rand_bytes(12)
		_ = :random.seed(a,b,c)
		_ = :pg2.join(@pg2_group, self)
		_ = WebDriver.start_browser(config) |> retry
		_ = WebDriver.start_session(browser, session) |> retry
		{:ok, _} = WebDriver.Session.url(session, url) |> retry
		:timer.sleep(5000)
		_ = if (mode == :page), do: ({:ok, _} = WebDriver.Session.window_size(session, :current, x_res, y_res) |> retry)
		{:ok, %Megaclicker{args | elem_val: WebDriver.Session.element(session, elem_type, elem_selector)}, @ttl}
	end

	def handle_info(:timeout, state = %Megaclicker{session: session, elem_val: elem_val, x_from: x_from, x_to: x_to, y_from: y_from, y_to: y_to, mode: :page}) do
		{:ok, _} = WebDriver.Mouse.move_to(elem_val, Megaclicker.range(x_from, x_to), Megaclicker.range(y_from, y_to)) |> retry
		{:ok, _} = WebDriver.Mouse.click(session, :left) |> retry
		{:noreply, state, @ttl}
	end
	def handle_info(:timeout, state = %Megaclicker{session: session, elem_val: elem_val, mode: :elem, elem_type: elem_type, elem_selector: elem_selector}) do
		case WebDriver.Element.size(elem_val) |> retry do
			%{width: this_x, height: this_y} ->
				{:ok, _} = WebDriver.Mouse.move_to(elem_val, round(this_x) |> :random.uniform, round(this_y) |> :random.uniform) |> retry
				{:ok, _} = WebDriver.Mouse.click(session, :left) |> retry
				{:noreply, state, @ttl}
			some ->
				IO.puts("cannot get size of elem #{inspect some}")
				case WebDriver.Session.element(session, elem_type, elem_selector) do
					elem_val = %WebDriver.Element{} -> %Megaclicker{state | elem_val: elem_val}
					some -> raise("cannot get elem #{inspect some}")
				end
		end
	end

	def handle_call(:force_exit, _, state = %Megaclicker{session: session, config: %WebDriver.Config{name: browser}}) do
		File.write!("./screenshots/#{Atom.to_string(session)}_#{Exutils.makestamp}.png", WebDriver.Session.screenshot(session) |> Base.decode64!)
		:timer.sleep(1000)
		{:stop, :normal, (WebDriver.stop_browser(browser) |> retry), state}
	end

	def terminate(:normal, _), do: :ok
	def terminate(reason, %Megaclicker{config: %WebDriver.Config{name: browser}}) do
		IO.puts("ERROR, TERMINATE worker, reason #{inspect reason}")
		WebDriver.stop_browser(browser) |> retry
		:ok
	end

end
