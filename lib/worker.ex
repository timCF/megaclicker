use Silverb, [
	{"@pg2_group", :clients}
]
use GenServer
def init(args = %{config: config = %WebDriver.Config{name: browser}, session: session, url: url}) do
	_ = :pg2.join(@pg2_group, self)
	_ = fn() -> WebDriver.start_browser(config)
	_ = WebDriver.start_session(browser, session)

end
@spec handle_info(:timeout, %{}) :: {:noreply, %{}, unquote(ttl)}
def handle_info(:timeout, state = %{}), do: {:noreply, cachex_handle(state), unquote(ttl)}
@spec start_link(any) :: {:ok, pid}
def start_link(args), do: unquote(start_link_body)
@spec start_link :: {:ok, pid}
def start_link do
	args = %{}
	unquote(start_link_body)
end

defmacrop retry(body) do
	quote location: :keep do
		Exutils.retry(fn() -> unquote(body) end, &pred/1, 5, 500)
	end
end
defp pred(some) when is_tuple(some), do: (elem(some,0) == :ok)
defp pred(_), do: false
