defmodule BloggyWeb.Admin do
  import Resourceful

  resource Elixir.Bloggy.Blog.Post, "posts", repo: Bloggy.Repo
end
