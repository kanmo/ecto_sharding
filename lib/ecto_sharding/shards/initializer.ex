defmodule Ecto.Sharding.Shards.Initializer do
  defmacro __using__(opts) do
    config = Keyword.fetch!(opts, :config)

    quote do
      import Ecto.Sharding.Shards
      import Logger
      import Ecto.Query

      @app_name unquote(config[:app_name])
      @databases Application.get_env(@app_name, unquote(config[:config_key]))
      unless @databases do
        raise "Config #{unquote(config[:config_key])} can't be nil"
      end

      @base_module_name unquote(config[:base_module_name])
      @repository_name unquote(config[:name])
      @table_name unquote(config[:table])
      @sequence_table_name unquote(config[:sequence_table_name])


      def generate_repository_supervisor(children) do
        count = @databases[:count]

        if count && count > 0 do
          import Supervisor.Spec, warn: false
          # TODO: name
          worker_name = unquote(Ecto.Sharding.Repositories.UserWorker)
          supervisor_name = unquote(Ecto.Sharding.Repositories.UserSupervisor)
          # supervisor(module, args, options)
          children ++ [
            supervisor(Ecto.Sharding.Repositories.ShardedSupervisor,
              [%{ worker_name: worker_name,
                  utils: __MODULE__,
                  name: supervisor_name
                }],
              [id: make_ref()])
          ] ++ [
            supervisor(Ecto.Sharding.Repositories.SequencerSupervisor,
              [%{ worker_name: Ecto.Sharding.Repositories.SequenceWorker,
                  utils: __MODULE__,
                  name: Ecto.Sharding.Repositories.SequenceSupervisor
                }],
              [id: make_ref()]
            )
          ]
        else
          children
        end
      end

      def databases_key(key), do: @databases[key]

      def repositories_to_load do
        for n <- 0..(@databases[:count] - 1) do
          __MODULE__.create_repository_module(n)
        end
      end

      def create_repository_module(position) do
        db = Enum.at(@databases[:databases], position)
        mod = repository_module(position)
        Application.put_env(@app_name, mod, db)

        Ecto.Sharding.Shards.create_repository_module(%{position: position, table: @table_name, app_name: @app_name, module: mod})

        ecto_repos = Application.get_env(@app_name, :ecto_repos)
        Application.put_env(@app_name, :ecto_repos, ecto_repos ++ [mod])

        mod
      end

      def create_sequencer_module do
        db = @databases[:sequencer]
        mod = Module.concat([@base_module_name, Sequencer])
        Application.put_env(@app_name, mod, db)

        Ecto.Sharding.Shards.create_sequencer_module(%{table: @sequence_table_name, app_name: @app_name, module: mod})

        ecto_repos = Application.get_env(@app_name, :ecto_repos)
        Application.put_env(@app_name, :ecto_repos, ecto_repos ++ [mod])

        mod
      end

      def repository_module(position) do
        repository_module_name(@base_module_name, @repository_name, position)
      end


    end
  end

end
