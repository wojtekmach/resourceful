defmodule BloggyWeb.Admin do
  import Resourceful

  resource :post,
    context: BloggyWeb.Admin.Blog,
    schema: BloggyWeb.Admin.Blog.Post,
    table: "posts",
    repo: Bloggy.Repo
end
