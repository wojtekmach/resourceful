defmodule Resourceful do
  defmacro resource(name, opts) do
    quote [location: :keep] do
      resource_name = unquote(name)
      resource = Enum.into(unquote(opts), %{name: resource_name})
      app_namespace = Map.fetch!(resource, :app_namespace)
      web_namespace = Map.fetch!(resource, :web_namespace)
      table = Map.fetch!(resource, :table)

      resource =
        resource
        |> Map.put_new(:singular, Phoenix.Naming.humanize(resource_name))
        |> Map.put_new(:plural, Phoenix.Naming.humanize(table))
        |> Map.put_new(:repo, Module.concat([app_namespace, Repo]))
        |> Map.put_new(:routes, Module.concat([web_namespace, Router, Helpers]))
        |> Map.put_new(:error_helpers, Module.concat([web_namespace, ErrorHelpers]))
        |> Map.put_new(:layout, {Module.concat([web_namespace, LayoutView]), "app.html"})

      fun = fn ->
        case Resourceful.SchemaBuilder.fields_from_table(resource.repo, resource.table) do
          {:ok, fields} ->
            fields

          {:error, _} ->
            require Logger
            Logger.warn("could not fetch fields due to DB connection error")
            []
        end
      end

      resource = Map.put_new_lazy(resource, :fields, fun)
      field_html_types = Map.get(resource, :field_html_types, [])
      field_html_types =
        for {name, {type, opts}} <- resource.fields do
          html_type = Keyword.get(field_html_types, name, type)
          {name, {html_type, opts}}
        end
      resource = Map.put(resource, :field_html_types, field_html_types)

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
          changeset = Ecto.Changeset.cast(struct, params, Keyword.keys(@fields))
          Enum.reduce(@fields, changeset, fn {name, {_type, opts}}, changeset ->
            if opts[:nullable?] == false do
              Ecto.Changeset.validate_required(changeset, name)
            else
              changeset
            end
          end)
        end
      end

      defmodule resource.schema do
        use Ecto.Schema
        @fields resource.fields

        schema resource.table do
          for {name, {type, _opts}} <- @fields do
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
        import Resourceful.ViewHelpers, only: [display: 3, display: 4], warn: false
        @resource resource

        def input(f, name, type, opts, html_opts) do
          label_text =
            if opts[:nullable?] do
              Phoenix.Naming.humanize(name)
            else
              Phoenix.Naming.humanize(name) <> "*"
            end

          content_tag :div, class: "form-group" do
            [
              label(f, name, label_text, class: "control-label"),
              Resourceful.ViewHelpers.input(f, name, type, html_opts),
              error_tag(f, name)
            ]
          end
        end

        def error_tag(form, field) do
          @resource.error_helpers.error_tag(form, field)
        end

        def translate_error(arg) do
          @resource.error_helpers.translate_error(arg)
        end
      end
    end
  end
end

defmodule Resourceful.SchemaBuilder do
  @moduledoc false

  def fields_from_table(repo, table) do
    repo_module = Keyword.fetch!(repo.config(), :repo)

    # TODO: private API!
    Mix.Ecto.ensure_repo(repo_module, [])
    Mix.Ecto.ensure_started(repo_module, [])

    with {:ok, result} <- get_fields(repo, table) do
      columns = Enum.map(result.rows, &Enum.into(Enum.zip(result.columns, &1), %{}))

      fields =
        for row <- columns, row["column_name"] != "id" do
          name = String.to_atom(row["column_name"])
          type = resourceful_type(row["data_type"])
          nullable? = row["is_nullable"] == "YES"

          {name, {type, nullable?: nullable?}}
        end

      {:ok, fields}
    end
  end

  defp get_fields(repo, table) do
    sql = "SELECT * FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2"
    repo.query(sql, ["public", table])
  end

  defp resourceful_type("character varying"), do: :string
  defp resourceful_type("text"), do: :text
  defp resourceful_type("timestamp without time zone"), do: :utc_datetime
  defp resourceful_type("date"), do: :date
  defp resourceful_type("bigint"), do: :integer

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
    opts = Keyword.put_new(opts, :rows, 5)
    textarea(f, name, opts)
  end
  def input(f, name, :integer, opts) do
    number_input(f, name, opts)
  end
  def input(f, name, :date, opts) do
    builder = fn b ->
      [
        b.(:year, [class: "form-control"]),
        " / ",
        b.(:month, [class: "form-control"]),
        " / ",
        b.(:day, [class: "form-control"]),
      ]
    end
    opts = Keyword.put_new(opts, :builder, builder)

    content_tag :div, class: "form-inline" do
      date_select(f, name, opts)
    end
  end
  def input(f, name, :url, opts) do
    url_input(f, name, opts)
  end

  def display(struct, name, type, opts \\ [])
  def display(struct, name, :text, _opts) do
    Phoenix.HTML.Format.text_to_html(Map.fetch!(struct, name))
  end
  def display(struct, name, :url, _opts) do
    value = Map.fetch!(struct, name)
    link value, to: value
  end
  def display(struct, name, _, _opts) do
    Map.fetch!(struct, name)
  end
end
