defmodule Megaclicker do
  use Silverb
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Megaclicker.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Megaclicker.Supervisor]
    Supervisor.start_link(children, opts)
  end

	def range(stop, stop), do: stop
	def range(start, stop) when (stop > start), do: (:random.uniform(stop - (start-1)) + (start-1))

end
