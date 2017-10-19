defmodule Ecto.Sharding.Shards.SequencerInitializer do
  defmacro __using__(_) do
    quote do
      import Ecto.Sharding.Shards
      import Logger
      import Ecto.Query

      @app_name Application.get_env(:ecto_sharding, :config)[:app_name]
      @base_module_name Application.get_env(:ecto_sharding, :config)[:base_module_name]
      @sequencer_config Application.get_env(@app_name, :sequencer)

      def create_sequencer_module do
        db = @sequencer_config[:sequencer]
        mod = sequencer_module_name(@base_module_name, Sequencer)
        Application.put_env(@app_name, mod, db)

        Ecto.Sharding.Shards.create_sequencer_module(%{table: @sequencer_config[:table], app_name: @app_name, module: mod})

        ecto_repos = Application.get_env(@app_name, :ecto_repos)
        Application.put_env(@app_name, :ecto_repos, ecto_repos ++ [mod])

        mod
      end

      def generate_sequencer_repository_supervisor(children) do
        import Supervisor.Spec, warn: false

        children ++ [
          supervisor(Ecto.Sharding.Repositories.SequencerSupervisor,
            [%{ worker_name: @sequencer_config[:worker_name],
                utils: __MODULE__,
                name: @sequencer_config[:supervisor_name]}],
            [id: make_ref()])
        ]
      end

      def next_sequence_id do
        update_query = "UPDATE `#{@sequencer_config[:table]}` SET id = LAST_INSERT_ID(id + 1)"
        mod = sequencer_module_name(@base_module_name, Sequencer)
        resp = mod.run(update_query)

        resp.last_insert_id
      end
    end
  end
end
