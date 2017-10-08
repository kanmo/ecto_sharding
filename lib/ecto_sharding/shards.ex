defmodule Ecto.Sharding.Shards do

  def create_repository_module(%{module: module} = params) do
    case :erlang.function_exported(module, :__info__, 1) do
      false -> do_create_module(params)
      _ -> nil
    end

    module
  end

  def repository_module_name(base, name, position) do
    Module.concat([base, "#{name}#{position}"])
  end

  def do_create_module(%{position: position, table: table, app_name: app_name, module: module}) do
    Module.create(module,
      quote do
        use Ecto.Repo, otp_app: unquote(app_name)

        def run(sql, params \\ []) do
          Ecto.Adapters.SQL.query!(__MODULE__, sql, params)
        end

      end, Macro.Env.location(__ENV__))
  end
end
