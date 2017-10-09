defmodule Ecto.Sharding.Repositories.SequencerSupervisor do
  use Supervisor

  def start_link(%{name: name} = opts) do
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(%{utils: utils, worker_name: name} = _) do
    mod = utils.create_sequencer_module
    children = [worker(mod, [], [id: make_ref(), name: name])]
    supervise(children, strategy: :one_for_one)
  end
end
