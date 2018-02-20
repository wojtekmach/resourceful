defmodule BloggyWeb.AdminTest do
  use Bloggy.DataCase, async: true

  test "schema" do
    assert Bloggy.Blog.Post.__schema__(:types) == %{id: :id, title: :string, body: :string}
  end

  test "context" do
    assert [] = Bloggy.Blog.list()

    {:ok, _} = Bloggy.Blog.create(%{title: "Hello", body: "Hello World!"})

    [post] = Bloggy.Blog.list()
    assert post.title == "Hello"
    assert post.body == "Hello World!"

    post = Bloggy.Blog.get!(post.id)
    assert post.title == "Hello"

    {:ok, updated} = Bloggy.Blog.update(post, %{body: "Good evening!"})
    assert updated.body == "Good evening!"

    {:ok, %Bloggy.Blog.Post{}} = Bloggy.Blog.delete(updated)

    assert [] = Bloggy.Blog.list()
  end
end
