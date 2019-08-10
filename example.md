# Rust qaraidel example

Header 1 should tell what this file is about. Simple paragraphs like that tell
something in detail. Codeblocks that contain source code in Rust are called
codelets. In simple sections like that they get extracted as is.

```rust
use std::io::*;
```

## pub mod liner

You can specify modules like that. Braces get inserted automatically. Every
subsection will be part of this module.

### pub struct Line

No code is needed to declare a struct. Use list:

- `pub no: i32`
  Put struct field after the bullet and the description on the next line. The
  backticks are optional, but it's better to use them to keep the document 
  readable in Markdown renderers. You can also leave an entry without docs.
- `pub content: String`
  The text on the first line gets inserted to the resulting code as is, no
  checks are done.

### impl Line

Impl blocks are also supported.

#### pub fn new

Quote will end up in resulting code, unlike simple paragraphs that will
get stripped. You can use it for things like derive or test annotations,
because it will be placed before function declaration:

> #[derive(Debug)]

1. `Line`
  Return types are declared using numbered lists.

```rust
// This is body of the function.
Line {
    no: 0,
    content: "".to_string(),
}
```

#### pub fn as_tuple

Parameters are declared using lists, no list means no parameters.

- `self`
  This is similar to struct fields.

1. `i32`
  You can specify several return types.
2. `String`
  They will end up in a tuple.

```rust
(self.no, self.content)
```

### enum LineType

As with structs, no codelets are necessary to declare an enum.

- `Normal`
  Though you can document it!
- `Strange`

Your file must should with blank line.

## mod other_mod 
