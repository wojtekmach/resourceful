defmodule BloggyWeb.Admin do
  import Resourceful

  resource :post,
    repo: Bloggy.Repo,
    routes: BloggyWeb.Router.Helpers,
    error_helpers: BloggyWeb.ErrorHelpers,
    layout: {BloggyWeb.LayoutView, "app.html"},
    scope: :admin,
    singular: "Post",
    plural: "Posts",
    table: "posts",
    context: BloggyWeb.Admin.Blog,
    schema: BloggyWeb.Admin.Blog.Post,
    controller: BloggyWeb.Admin.PostController,
    view: BloggyWeb.Admin.PostView
end
