defmodule BloggyWeb.Admin do
  import Resourceful

  resource :post,
    table: "posts",
    app_namespace: Bloggy,
    web_namespace: BloggyWeb,
    scope: :admin,
    context: BloggyWeb.Admin.Blog,
    schema: BloggyWeb.Admin.Blog.Post,
    controller: BloggyWeb.Admin.PostController,
    view: BloggyWeb.Admin.PostView
end
