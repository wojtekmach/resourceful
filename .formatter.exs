# Used by "mix format"
[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      resource: 2
    ]
  ]
]
