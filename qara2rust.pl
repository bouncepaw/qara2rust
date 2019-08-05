#!/usr/bin/perl
use 5.010;
use strict; 
use warnings;

sub is_header {
  my ($line) = @_;
  return $line =~ /^\#{1,6} .*/;
}

# 0: line to parse.
# 1: variable where to save header level.
# 2: variable where to save header text.
sub extract_header {
  my ($line) = $_[0];
  $line =~ /^(\#{1,6}) (.*)$/;
  $_[1] = length $1;
  $_[2] = $2;
}

my %special_header_triggers = 
  map { $_ => 1 } ( "pub", "impl", "fn", "mod", "struct", "enum" );

sub line_type {
  my ($line) = @_;
  # Only subset of Markdown that is important for Qaraidel is checked.
  return 'header' if $line =~ m/^\s*\#{1,6} /;
  return 'fence'  if $line =~ m/^\s*```/;
  return 'bullet' if $line =~ m/^\s*[\*\-\+] /;
  return 'index'  if $line =~ m/^\s*\d+\. /;
  return 'quote'  if $line =~ m/^\s*\> /;
  return 'blank'  if $line =~ m/^\s*$/;
  return 'text';
}

sub is_special_header {
  my $header_text = $_[0];
  # Extract first word.
  $header_text =~ /^([a-z]*)/;
  return exists $special_header_triggers{$1};
}

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

Supported Markdown subset
  As Qaraidel has quite limited scope, there's no need to 
  support full Markdown, thus only subset is supported. This 
  section tells which parts of it are supported.

  Headers
    Only those that start with hashes are supported.
    ## legal header
    ## Hashes on the right will be parsed as part of headline ##

  Lists
    Ordered ones and unordered ones with these bullets: - + *.
    1. legal
    - legal
    + legal
    * legal
      This is part of entry. Minimal indent = 2, no empty line.

      This is not.
    This is not.

  Fenced codeblocks
    Only those that are delimited with triple backticks.
    ```language
    Indentation on the left of this line is retained.
    ```

  Quote
    Every line has to start with greater than character.
    > And so she said:
    > > Ain't got no CommonMark.

  Everything Qaraidel doesn't understand will be thought of as 
  simple text paragraphs. Thus, nothing special happens to 
  them. They will end up as is in resulting text.
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

my $nest_level = 0;
my $prev_header_level = 0;
my $curr_header_level = 0;
my $this_section_is_special = 0;

if ($should_weave) {
  my $in_codelet = 0;
  my $would_be_nice_to_clean_blank = 0;
  while (<STDIN>) {
    my $type = line_type $_;
    if ($type eq "fence") {
      # Invert state.
      $in_codelet = $in_codelet ? 1 : 0;
      $would_be_nice_to_clean_blank = 1 unless $in_codelet;
    } 
    elsif ($type eq "quote") {
      $would_be_nice_to_clean_blank = 1;
    }
    elsif ($type eq "blank" and $would_be_nice_to_clean_blank) {
      $would_be_nice_to_clean_blank = 0;
    }
    else {
      $would_be_nice_to_clean_blank = 0;
      print $_;
    }
  }
}
else {
  while (<STDIN>) {
    my $type = line_type $_;
    print "$type  $_";
  }
}

