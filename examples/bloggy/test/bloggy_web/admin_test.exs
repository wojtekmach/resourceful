defmodule BloggyWeb.AdminTest do
  use Bloggy.DataCase, async: true
  alias BloggyWeb.Admin.{Blog, Blog.Post}

  test "schema" do
    assert Post.__schema__(:types) == %{id: :id, title: :string, body: :string}
  end

  test "context" do
    assert [] = Blog.list()

    {:ok, _} = Blog.create(%{title: "Hello", body: "Hello World!"})

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
end
