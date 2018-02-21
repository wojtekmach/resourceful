# Bloggy

The only additions to a brand new Phoenix app are:

1. [migration file](./priv/repo/migrations/20180220220538_create_posts.exs)
2. [Admin module](./lib/bloggy_web/admin.ex) - it automatically generates Schema, Controller, View etc
3. [Admin scope in router](./lib/bloggy_web/router.ex)

## Setup

```
mix setup
iex -S mix server
```

```
open http://localhost:4000/admin/posts
```
