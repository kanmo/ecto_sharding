ExUnit.start()

user_databases = [
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_0",
    hostname: "localhost",
    pool_size: 5,
    slot: 0..262143
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_1",
    hostname: "localhost",
    pool_size: 5,
    slot: 262144..524287
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_2",
    hostname: "localhost",
    pool_size: 5,
    slot: 524288..786431
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_3",
    hostname: "localhost",
    pool_size: 5,
    slot: 786432..1048575
  ]
]

Application.put_env(:ecto_sharding, :config, [
      app_name: :ecto_sharding,
      base_module_name: Ecto.Sharding.ShardedRepositories
    ])

Application.put_env(:ecto_sharding, :cluster, [
      databases: user_databases,
      count: Enum.count(user_databases),
      name: "Users",
      table: "users",
      distkey: "email",
      worker_name: Ecto.Sharding.Repositories.Users,
      supervisor_name: Ecto.Sharding.Repositories.UserSupervisor,
      slot_size: 1048576
    ])

Application.put_env(:ecto_sharding, :ecto_repos, [])

defmodule Ecto.Sharding.Shards.Users do
  use Ecto.Sharding.Shards.ShardingInitializer
end

children = Ecto.Sharding.Shards.Users.generate_sharding_repository_supervisor([])
opts = [strategy: :one_for_one, name: Ecto.Sharding.Supervisor]

import Supervisor.Spec, warn: false
Supervisor.start_link(children, opts)
