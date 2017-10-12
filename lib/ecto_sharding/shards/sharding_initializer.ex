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
        count = Application.get_env(:sharding_app, :cluster)[:count]

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
        id = next_sequence_id
        position = shard_for(@cluster_config[:count], id)
        sharded_changeset = Ecto.Changeset.change(changeset, %{user_id: id})
        insert_all(position, @cluster_config[:table], [sharded_changeset.changes])
      end

      def insert_all(position, table_name, changeset) when is_list(changeset) do
        repository_module_name(@base_module_name, @cluster_config[:name], position).insert_all(table_name, changeset, [])
      end

      def insert_all(position, table_name, changeset) do
        insert_all(position, table_name, [changeset])
      end

      def repository(user_id) do
        repository_module(shard_key(user_id))
      end

      def shard_key(user_id) do
        Integer.mod(user_id, @cluster_config[:count])
      end
    end
  end
end
