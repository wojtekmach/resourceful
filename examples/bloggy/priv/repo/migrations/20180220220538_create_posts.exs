defmodule Bloggy.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string, null: false
    end

    create table(:posts) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :published_on, :date
      add :author_id, references(:authors)
    end
  end
end
