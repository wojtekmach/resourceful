defmodule BloggyWeb.AdminTest do
  use BloggyWeb.ConnCase, async: true
  alias BloggyWeb.Admin.{Blog, Blog.Post, Blog.Authors}
  alias BloggyWeb.Router.Helpers, as: Routes

  test "schema" do
    assert %{id: :id, title: :string, body: :string} = Post.__schema__(:types)
  end

  test "context" do
    {:ok, alice} = Authors.create(%{name: "Alice"})

    assert [] = Blog.list()

    {:ok, _} = Blog.create(%{title: "Hello", body: "Hello World!", author_id: alice.id})

    [post] = Blog.list()
    assert post.title == "Hello"
    assert post.body == "Hello World!"

    post = Blog.get!(post.id)
    assert post.title == "Hello"

    {:ok, updated} = Blog.update(post, %{body: "Good evening!"})
    assert updated.body == "Good evening!"

    {:ok, %Post{}} = Blog.delete(updated)

    assert [] = Blog.list()
  end

  test "constraints" do
    {:error, changeset} = Authors.create(%{name: ""})
    assert {"can't be blank", _} = changeset.errors[:name]
  end

  test "controller" do
    conn = get(build_conn(), "/admin/posts")
    assert html_response(conn, 200) =~ "Listing Posts"

    conn = get(build_conn(), "/admin/posts/new")
    assert html_response(conn, 200) =~ "New Post"

    {:ok, post} = Blog.create(%{title: "Hello", body: "Hello World!"})

    conn = get(build_conn(), Routes.admin_post_path(conn, :show, post))
    assert html_response(conn, 200) =~ "Show Post"

    conn = get(build_conn(), Routes.admin_post_path(conn, :edit, post))
    assert html_response(conn, 200) =~ "Edit Post"

    conn = put(build_conn(), Routes.admin_post_path(conn, :update, post), %{resource: %{title: "Updated!"}})
    assert Blog.get!(post.id).title == "Updated!"
    assert redirected_to(conn) == Routes.admin_post_path(conn, :show, post)

    conn = delete(build_conn(), Routes.admin_post_path(conn, :delete, post))
    assert redirected_to(conn) == Routes.admin_post_path(conn, :index)
    assert [] = Blog.list()
  end
end
