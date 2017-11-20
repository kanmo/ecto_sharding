# EctoSharding

Simple Database Sharding in Ecto.

Ecto Repository distributed multiple databases.

### Support database
- MySQL

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_sharding` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_sharding, "~> 0.1.0"}
  ]
end
```

### Usage
#### Add database connections to you application's config/#{env}.exs:

```elixir
user_databases = [
  [
    adapter: Ecto.Adapters.MySQL,
    username: "mysql_user",
    password: "password",
    database: "user_0",
    hostname: "localhost",
    pool_size: 5,
    slot: 0..262143
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "mysql_user",
    password: "password",
    database: "user_1",
    hostname: "localhost",
    pool_size: 5,
    slot: 262144..524287
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "mysql_user",
    password: "password",
    database: "user_2",
    hostname: "localhost",
    pool_size: 5,
    slot: 524288..786431
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "mysql_user",
    password: "password",
    database: "user_3",
    hostname: "localhost",
    pool_size: 5,
    slot: 786432..1048575
  ]
]

config :ecto_sharding, :config, [
  app_name: :your_app_name,
  base_module_name: YourAppName.ShardedRepositories
]

config :sharding_app, :cluster, [
  databases: user_databases,
  count: Enum.count(user_databases),
  name: "Users",
  table: "users",
  distkey: "email",
  worker_name: YourAppName.Repositories.Users,
  supervisor_name: YourAppName.Repositories.UserSupervisor,
  slot_size: 1048576
]

config :sharding_app, ecto_repos: []
```

#### Add this example your application's lib/your_app_name/shards/users.ex:

```elixir
defmodule YourAppName.Shards.Users do
  use Ecto.Sharding.Shards.ShardingInitializer
end
```

#### Add the sharding ecto repository to your supervisor tree

```elixir
defmodule YourAppName do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = YourAppName.Shards.Users.generate_sharding_repository_supervisor([])
    opts = [strategy: :one_for_one, name: YourAppName.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

#### Get the ecto repository module for a dist_key

```elixir
repository = YourApp.Shards.Users.fetch_repo(user.email)
```

## Thanks
This library was made with reference to [activerecord-sharding](https://github.com/hirocaster/activerecord-sharding).
I thank the author of the activerecord-sharding.
