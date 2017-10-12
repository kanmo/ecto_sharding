defmodule EctoShardingTest do
  use ExUnit.Case, async: true

  import Ecto.Sharding.Shards.Users

  @base_module_name ShardingApp.ShardedRepositories
  @cluster_config Application.get_env(:ecto_sharding, :cluster)
  @sequencer_config Application.get_env(:ecto_sharding, :sequencer)

  describe "Repository Modules" do
    test "repository module name is correct for database name" do
      for (n <- 0..@cluster_config[:count] - 1) do
        assert Ecto.Sharding.Shards.repository_module_name(@base_module_name, @cluster_config[:name], n) == Module.concat([@base_module_name, "#{@cluster_config[:name]}#{n}"])
      end
    end

    test "repository for each database has been created" do
      for (n <- 0..@cluster_config[:count] - 1) do
        mod = repository_module(n)
        assert :erlang.function_exported(mod, :__info__, 1) == true
      end
    end
  end
end
