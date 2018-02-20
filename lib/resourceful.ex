defmodule Resourceful do
  defmacro resource(schema, table, opts) do
    quote [location: :keep] do
      fields = Resourceful.SchemaBuilder.fields(unquote(table), unquote(opts))

      defmodule unquote(schema) do
        use Ecto.Schema
        @fields fields

        schema unquote(table) do
          for {name, type} <- @fields do
            field name, type
          end
        end
      end
    end
  end
end

defmodule Resourceful.SchemaBuilder do
  @moduledoc false

  def fields(table, opts) do
    repo = Keyword.fetch!(opts, :repo)
    Keyword.get_lazy(opts, :fields, fn -> fields_from_table(repo, table) end)
  end

  defp fields_from_table(repo, table) do
    Application.ensure_all_started(:ecto)
    Application.ensure_all_started(:postgrex)
    repo_module = Keyword.fetch!(repo.config(), :repo)
    children = [repo_module]
    Supervisor.start_link(children, strategy: :one_for_one)

    sql = """
    SELECT *
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = $1;
    """

    result = repo.query!(sql, [table])
    columns = Enum.map(result.rows, &Enum.into(Enum.zip(result.columns, &1), %{}))

    for %{"column_name" => name, "data_type" => type} <- columns,
        name != "id" do
      {String.to_atom(name), to_ecto_type(type)}
    end
  end

  defp to_ecto_type("character varying"), do: :string
  defp to_ecto_type("text"), do: :string
end
