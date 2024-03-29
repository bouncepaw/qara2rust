# qara2rust

Qaraidel to Rust transpiler.

## What is Qaraidel?

Qaraidel is a tool that generates code from Markdown documents
written in a special way. Its goal to make literate programming
and documentation easier and more straight-forward using familiar
markdown syntax.

From this:

```md
## enum Weather
- Rainy
- Sunny
```

To this:

```rust
enum Weather {
    Rainy,
    Sunny
}
```

The more complicated example can be found here:

- [example.md as rendered by GitHub](example.md)
- [the same file as it is written in text editor](
  https://raw.githubusercontent.com/bouncepaw/qara2rust/master/example.md)
- [example.rs generated by Qaraidel](example.rs)
- [and the same file after formatting](example.fmt.rs)

## What is qara2rust?

This is the first implementation of Qaraidel for Rust programming
language written in Perl.

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

## What language elements are supported?

- Enums
- Structs
- Impl blocks
- Modules
- Functions

You can also write Rust code directly, of course.

## Installation

Save file `qara2rust.pl` somewhere in your `$PATH` (in this
example I save it as `~/bin/qara2rust`, change as you wish):

```sh
git clone https://github.com/bouncepaw/qara2rust.git
cd qara2rust
mv qara2rust.pl ~/bin/qara2rust
```

## Contributing

If there is a bug or a feature you would like to see, open an issue
or make a pull request.
