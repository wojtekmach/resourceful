defmodule Resourceful do
  defmacro resource(name, opts) do
    error_helpers = Keyword.fetch!(opts, :error_helpers)

    quote [location: :keep] do
      resource = Enum.into(unquote(opts), %{name: unquote(name)})
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
            field name, Resourceful.SchemaBuilder.ecto_type(type)
          end
        end
      end

      defmodule resource.controller do
        @resource resource

        import Plug.Conn

        def init(opts) do
          opts
        end

        def call(conn, action) do
          conn
          |> put_private(:resourceful_resource, @resource)
          |> Phoenix.Controller.put_layout(@resource.layout)
          |> Phoenix.Controller.put_view(@resource.view)
          |> Resourceful.ResourceController.call(action)
        end
      end

      defmodule resource.view do
        use Phoenix.View, root: Path.join([:code.priv_dir(:resourceful), "templates"]), path: "resource"
        use Phoenix.HTML
        import Phoenix.Controller, only: [get_flash: 2, view_module: 1], warn: false
        import Resourceful.Routes
        import unquote(error_helpers)

        def input(f, name, type, opts) do
          content_tag :div, class: "form-group" do
            [
              label(f, name, class: "control-label"),
              Resourceful.ViewHelpers.input(f, name, type, opts),
              error_tag(f, name)
            ]
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

    sql = "SELECT * FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2"
    result = repo.query!(sql, ["public", table])
    columns = Enum.map(result.rows, &Enum.into(Enum.zip(result.columns, &1), %{}))

    for %{"column_name" => name, "data_type" => type} <- columns,
        name != "id" do
      {String.to_atom(name), resourceful_type(type)}
    end
  end

  defp resourceful_type("character varying"), do: :string
  defp resourceful_type("text"), do: :text

  def ecto_type(:text), do: :string
  def ecto_type(other), do: other
end

defmodule Resourceful.Routes do
  def resource_path(conn, resource, args) do
    fun = :"#{resource.scope}_#{resource.name}_path"
    apply(resource.routes, fun, [conn | args])
  end

  def resource_url(conn, resource, args) do
    fun = :"#{resource.scope}_#{resource.name}_url"
    apply(resource.routes, fun, [conn | args])
  end
end

defmodule Resourceful.ResourceController do
  use Phoenix.Controller
  import Resourceful.Routes

  defp resource(conn) do
    conn.private.resourceful_resource
  end

  def index(conn, _params) do
    resource = resource(conn)
    structs = resource.context.list()
    render(conn, "index.html", resource: resource(conn), structs: structs)
  end

  def new(conn, _params) do
    resource = resource(conn)
    changeset = resource.context.changeset(struct(resource(conn).schema), %{})
    render(conn, "new.html", resource: resource(conn), changeset: changeset)
  end

  def create(conn, %{"resource" => params}) do
    resource = resource(conn)
    case resource.context.create(params) do
      {:ok, struct} ->
        conn
        |> put_flash(:info, "#{resource(conn).singular} created successfully.")
        |> redirect(to: resource_path(conn, resource(conn), [:show, struct]))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", resource: resource(conn), changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    resource = resource(conn)
    struct = resource.context.get!(id)
    render(conn, "show.html", resource: resource(conn), struct: struct)
  end

  def edit(conn, %{"id" => id}) do
    resource = resource(conn)
    struct = resource.context.get!(id)
    changeset = resource.context.changeset(struct, %{})
    render(conn, "edit.html", resource: resource(conn), struct: struct, changeset: changeset)
  end

  def update(conn, %{"id" => id, "resource" => params}) do
    resource = resource(conn)
    struct = resource.context.get!(id)

    case resource.context.update(struct, params) do
      {:ok, struct} ->
        conn
        |> put_flash(:info, "#{resource(conn).singular} updated successfully.")
        |> redirect(to: resource_path(conn, resource(conn), [:show, struct]))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", resource: resource(conn), struct: struct, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    resource = resource(conn)
    struct = resource.context.get!(id)
    {:ok, _club} = resource.context.delete(struct)

    conn
    |> put_flash(:info, "#{resource(conn).singular} deleted successfully.")
    |> redirect(to: resource_path(conn, resource(conn), [:index]))
  end
end

defmodule Resourceful.ViewHelpers do
  use Phoenix.HTML

  def input(f, name, :string, opts) do
    text_input(f, name, opts)
  end

  def input(f, name, :text, opts) do
    textarea(f, name, opts)
  end
end
