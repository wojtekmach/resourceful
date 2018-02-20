defmodule Resourceful do
  defmacro resource(_name, opts) do
    quote [location: :keep] do
      resource = Enum.into(unquote(opts), %{})
      fun = fn -> Resourceful.SchemaBuilder.fields_from_table(resource.repo, resource.table) end
      resource = Map.put_new_lazy(resource, :fields, fun)

      defmodule resource.context do
        @schema resource.schema
        @fields resource.fields
        @repo resource.repo

        def list() do
          @repo.all(@schema)
        end

        def create(params) do
          struct(@schema)
          |> changeset(params)
          |> @repo.insert()
        end

        def get!(id) do
          @repo.get!(@schema, id)
        end

        def update(struct, params) do
          struct
          |> changeset(params)
          |> @repo.update()
        end

        def delete(struct) do
          @repo.delete(struct)
        end

        def changeset(struct, params) do
          Ecto.Changeset.cast(struct, params, Keyword.keys(@fields))
        end
      end

      defmodule resource.schema do
        use Ecto.Schema
        @fields resource.fields

        schema resource.table do
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

  def fields_from_table(repo, table) do
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
