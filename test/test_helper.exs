ExUnit.start()

user_databases = [
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_0",
    hostname: "localhost",
    pool_size: 5
  ],
  [
    adapter: Ecto.Adapters.MySQL,
    username: "root",
    password: "",
    database: "user_1",
    hostname: "localhost",
    pool_size: 5
  ]
]

user_sequencer = [
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "user_0",
  hostname: "localhost",
  pool_size: 5
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
      worker_name: Ecto.Sharding.Repositories.Users,
      supervisor_name: Ecto.Sharding.Repositories.UserSupervisor,
    ])

Application.put_env(:ecto_sharding, :sequencer, [
      sequencer: user_sequencer,
      table: "user_id",
      worker_name: Ecto.Sharding.Repositories.Sequencer,
      supervisor_name: Ecto.Sharding.Repositories.SequenceSupervisor
    ])

Application.put_env(:ecto_sharding, :ecto_repos, [])


defmodule Ecto.Sharding.Shards.Users do
  use Ecto.Sharding.Shards.ShardingInitializer
  use Ecto.Sharding.Shards.SequencerInitializer
end

children = Ecto.Sharding.Shards.Users.generate_sharding_repository_supervisor([]) ++ Ecto.Sharding.Shards.Users.generate_sequencer_repository_supervisor([])

opts = [strategy: :one_for_one, name: Ecto.Sharding.Supervisor]

import Supervisor.Spec, warn: false
Supervisor.start_link(children, opts)
