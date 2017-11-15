defmodule EctoShardingTest do
  use ExUnit.Case, async: true

  import Ecto.Sharding.Shards.Users

  defmodule UserSchema do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :email, :string
      field :inserted_at, :naive_datetime
    end

    def changeset(user, attrs) do
      user
      |> cast(attrs, [:email])
      |> validate_required([:email])
    end
  end

  @base_module_name EctoSharding.ShardedRepositories
  @cluster_config Application.get_env(:ecto_sharding, :cluster)

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
      email_addr = "example.com"
      changeset = UserSchema.changeset(%UserSchema{}, %{ email:  email_addr })
      Ecto.Sharding.Shards.Users.sharded_insert(changeset)

      repo =
        Integer.mod(:erlang.crc32(email_addr), @cluster_config[:slot_size])
        |> Ecto.Sharding.Shards.Users.fetch_repo

      result = repo.run("select exists (select * from users where email = '#{email_addr}')")
      assert result.rows == [[1]]
    end
  end

end
