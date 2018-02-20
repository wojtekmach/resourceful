defmodule BloggyWeb.AdminTest do
  use Bloggy.DataCase, async: true

  test "schema" do
    assert Bloggy.Blog.Post.__schema__(:types) == %{id: :id, title: :string, body: :string}
  end
end
