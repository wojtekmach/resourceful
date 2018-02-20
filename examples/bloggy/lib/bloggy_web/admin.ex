defmodule BloggyWeb.Admin do
  import Resourceful

  resource Blog, Blog.Post, "posts", repo: Bloggy.Repo
end
