#!/usr/bin/perl
use 5.010;
use strict; 
use warnings;

my $indent_size = 4;
my $should_weave = 0;

foreach (@ARGV) {
  my $opt = $_;

  if ($opt eq "-h" or $opt eq "--help") {
    say <<'EOK';
qara2rust 0.1.0
  Convert Qaraidel document with Rust source code in Markdown.
  Released under terms of MIT license.

  Input text is read from stdin and generated text is output 
  to stdout. You can use shell's capabilities to read from
  file or to save into file:

    Read file input.md
      cat input.md | qara2rust
      qara2rust < input.md

    Write to file output.md
      qara2rust > output.md

    You can combine them
      cat input.md | qara2rust > output.md

Options
  -h, --help
    Print this message and exit.

  --indent=<N>
    Set indentation size generated when expanding nested 
    blocks. Defaults to 4. If <N> equals 0, no indentation
    will be generated.

  --doc, --weave
    Strip codeblocks and output what's left. This can be used
    as documentation.
EOK
  exit 0;
  }

  elsif ($opt =~ /--indent=([0-9]*)/) {
    $indent_size = $1;
  }

  elsif ($opt eq "--doc" or $opt eq "--weave") {
    $should_weave = 1;
  }

  else {
    say "Unknown option: $opt";
  }
}

