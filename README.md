# qara2rust

Qaraidel to Rust transpiler.

## What is Qaraidel?

Qaraidel is a dialect of Markdown. Its goal is to make literate 
programming and documentation easier and more straight-forward
using familiar markup syntax.

## What is qara2rust?

This is the first implementation of Qaraidel for Rust programming
language.

## How do I use it?

Qara2rust reads source text from stdin and outputs text after 
processing to stdout. You can pipe the output to `rustfmt`, for
example.

This would read file `main.md` and save it to `main.rs`:

```sh
cat main.md | qara2rust > main.rs
```

This would also format the resulting code nicely and detect any
errors Rust compiler would:

```sh
cat main.md | qara2rust | rustfmt > main.rs
```

## What can it do?

TODO: tell what it can do

## Installation

Save it somewhere in your `$PATH`.
