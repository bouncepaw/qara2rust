# Rust qaraidel example

Header 1 should tell what this file is about. Simple paragraphs like that tell
something in detail. Codeblocks that contain source code in Rust are called
codelets. In simple sections like that they get extracted as is.

```rust
use std::io::*;
```
## pub mod liner

You can specify modules like that. Braces get inserted automatically. Every
section with headers lower than this section's one will be part of this
module.

### pub struct Line

No code is needed to declare a struct. Use list:

- `pub no: i32`
  Put struct field after the bullet and the description on the next line. The
  backticks are optional, but it's better to use them to keep the document 
  readable in Markdown renderers. You can also leave an entry without docs.
- `pub content: String`

### impl Line

Impl blocks are also supported. 

#### pub fn new

> This text will end up in resulting code, unlike simple paragraphs that will 
> get stripped. You can use it for things like derive or test annotations, 
> because it will be placed before declaration.

Parameters are declared using lists, no list = no parameters.

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

- `self`
  This is similar to struct fields.

1. `i32`
  You can specify several return types.
2. `String`
  They will end up in a tuple.

```rust
(self.no, self.content)
```

#### enum LineType

As with structs, no codelets are necessary to declare an enum.

- `Normal`
- `Strange`

Your file must end with blank line.

