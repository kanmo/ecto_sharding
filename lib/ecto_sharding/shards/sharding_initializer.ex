defmodule Ecto.Sharding.Shards.ShardingInitializer do
  defmacro __using__(_) do
    quote do
      import Ecto.Sharding.Shards
      import Logger
      import Ecto.Query

      @app_name Application.get_env(:ecto_sharding, :config)[:app_name]
      @base_module_name Application.get_env(:ecto_sharding, :config)[:base_module_name]
      @cluster_config Application.get_env(@app_name, :cluster)

      unless @cluster_config[:databases] do
        raise "Config cluster databases can't be nil"
      end

      def repositories_to_load do
        for n <- 0..(@cluster_config[:count] - 1) do
          __MODULE__.create_repository_module(n)
        end
      end

      def create_repository_module(position) do
        db = Enum.at(@cluster_config[:databases], position)
        mod = repository_module(position)
        Application.put_env(@app_name, mod, db)

        Ecto.Sharding.Shards.create_repository_module(%{position: position, table: @cluster_config[:table_name], app_name: @app_name, module: mod})

        ecto_repos = Application.get_env(@app_name, :ecto_repos)
        Application.put_env(@app_name, :ecto_repos, ecto_repos ++ [mod])

        mod
      end

      def repository_module(position) do
        repository_module_name(@base_module_name, @cluster_config[:name], position)
      end

      def generate_sharding_repository_supervisor(children) do
        count = Application.get_env(@app_name, :cluster)[:count]

        if count && count > 0 do
          import Supervisor.Spec, warn: false

          children ++ [
            supervisor(Ecto.Sharding.Repositories.ShardedSupervisor,
              [%{ worker_name: @cluster_config[:worker_name],
                  utils: __MODULE__,
                  name: @cluster_config[:supervisor_name]}],
              [id: make_ref()])
          ]
        else
          children
        end
      end

      def sharded_insert(changeset) do
        distkey = @cluster_config[:distkey] |> String.to_atom
        repo =
          Map.get(changeset.changes, distkey)
          |> fetch_repo

        repo.insert(changeset)
      end

      def fetch_repo(distkey) do
        slot = Integer.mod(:erlang.crc32(distkey), @cluster_config[:slot_size])
        repos = Application.get_env(@app_name, :ecto_repos)
        Enum.find(repos, fn repo ->
          Enum.member?(repo.config[:slot], slot)
        end)
      end

    end
  end
end
