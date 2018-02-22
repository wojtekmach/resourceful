defmodule BloggyWeb.Admin do
  @external_resource "priv/repo/migrations"

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

  resource :author,
    table: "authors",
    app_namespace: Bloggy,
    web_namespace: BloggyWeb,
    scope: :admin,
    context: BloggyWeb.Admin.Blog.Authors,
    schema: BloggyWeb.Admin.Blog.Author,
    controller: BloggyWeb.Admin.AuthorController,
    view: BloggyWeb.Admin.AuthorView,
    field_html_types: [
      website_url: :url
    ]
end
