defmodule Megaclicker.Worker do
	use Silverb, [
		{"@pg2_group", :clients},
		{"@ttl", 100}
	]
	use GenServer

	#
	#	priv
	#

	defmacrop retry(body) do
		quote location: :keep do
			Exutils.retry(fn() -> unquote(body) end, &pred/1, 4, 500)
		end
	end
	defp pred(some) when is_tuple(some), do: (elem(some,0) == :ok)
	defp pred(_), do: false

	#
	#	public
	#

	def start_link(args), do: GenServer.start_link(__MODULE__, args)
	def init(args = %{config: config = %WebDriver.Config{name: browser}, session: session, url: url}) do
		<<a::32,b::32,c::32>> = :crypto.rand_bytes(12)
		_ = :random.seed(a,b,c)
		_ = :pg2.join(@pg2_group, self)
		_ = WebDriver.start_browser(config) |> retry
		_ = WebDriver.start_session(browser, session) |> retry
		{:ok, _} = WebDriver.Session.url(session, url) |> retry
		{:ok, _} = WebDriver.Session.window_size(session, :current, 1024, 1024) |> retry
		{:ok, Map.put(args, :root_elem, WebDriver.Session.element(session, :tag, "body")), @ttl}
	end

	def handle_info(:timeout, state = %{session: session, root_elem: root_elem}) do
		{:ok, _} = WebDriver.Mouse.move_to(root_elem, Megaclicker.range(24,722), Megaclicker.range(287, 674)) |> retry
		{:ok, _} = WebDriver.Mouse.click(session, :left) |> retry
		{:noreply, state, @ttl}
	end

end
