defmodule BloggyWeb.Router do
  use BloggyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BloggyWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/admin", BloggyWeb.Admin, as: :admin do
    pipe_through :browser

    resources "/posts", PostController
    resources "/authors", AuthorController
  end
end
