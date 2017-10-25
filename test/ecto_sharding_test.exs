defmodule EctoShardingTest do
  use ExUnit.Case, async: true

  import Ecto.Sharding.Shards.Users

  defmodule UserSchema do
    use Ecto.Schema
    import Ecto.Changeset
    alias ShardingApp.User

    schema "users" do
      field :user_id, :integer
      field :message, :string
      field :inserted_at, Ecto.DateTime
T    end

    def changeset(user, attrs) do
      user
      |> cast(attrs, [:user_id, :message])
      |> validate_required([:message])
    end
  end


  @base_module_name EctoSharding.ShardedRepositories
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

  describe "Sharding" do
    test "insert from changeset" do
      changeset = UserSchema.changeset(%UserSchema{},
        %{ message: "from changeset" })
        user_id = Ecto.Sharding.Shards.Users.sharded_insert(changeset)

        repo = Ecto.Sharding.Shards.Users.repository(user_id)
        result = repo.run("select exists (select * from users where user_id = #{user_id})")
        assert result.rows == [[1]]
    end
  end

end
