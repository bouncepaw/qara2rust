#!/usr/bin/perl
use 5.010;
use strict; 
use warnings;
use experimental qw( switch );

sub New {
  my ($type, $header) = @_;
  ( 'type' => $type, 'header' => $header, 'body' => '' );
}

sub ApplyBulletedList {
  my (%obj, $line) = @_;
  given ($obj{'type'}) {
    when('fn') { 
      $obj{'header'} .= parse_bulleted_list_for_fn $line }
    when(/struct|enum/) {
      $obj{'body'} .= parse_bulleted_list_for_struct_or_enum $line }
    default {}
  }
  %obj;
}

# TODO: finish the rest:
sub ApplyNumberedList {}
sub ApplyQuote {}
sub ApplyCodelet {}

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
  map { $_ => 1 } ( "pub", "impl", "fn", "mod", "struct", "enum", "unsafe" );

# Only subset of Markdown that is important for Qaraidel is checked.
sub line_type {
  given ($_) {
    when(/^\s*\#{1,6} /)  { 'header' }
    when(/^\s*```/)       { 'fence'  }
    when(/^\s*[\*\-\+] /) { 'bullet' }
    when(/^\s*\d+\. /)    { 'index'  }
    when(/^\s*\> /)       { 'quote'  }
    when(/^\s*$/)         { 'blank'  }
    default               { 'text'   }
  }
}

# Remove bullet and optional backticks from list item.
sub disbullet {
  $_ =~ /^\s*[\*\-\+] \`?([^\`]*)/;
  $1;
}

# (line on which parsing ended,
#  result of parsing)
sub parse_bulleted_list_generic {
  my ($commencer, $joiner, $terminator, $first_line) = @_;
  my $res = $commencer . disbullet($_);

  while (<STDIN>) {
    my $type = line_type $_;
    return ($_, $res . $terminator) 
      unless $type eq 'bullet' or $type eq 'text';
    $res .= $joiner . disbullet $_ if $type eq 'bullet';
  }
}

sub parse_bulleted_list_for_fn {
  parse_bulleted_list_generic('(', ', ', ')', $_) }
sub parse_bulleted_list_for_struct_or_enum {
  parse_bulleted_list_generic("{\n    ", ",\n    ", "\n}", $_) }

sub is_special_header {
  my ($text) = @_;
  # Extract first word and check if it it special.
  if ($text =~ /^([a-z]*)/) {
    (exists $special_header_triggers{$1}) ? 1 : 0;
  } else {
    0;
  }
}

sub special_header_type {
  my ($text) = @_;
  my @words = split / /, $text;
  foreach (@words) {
    if ($_ =~ /(fn|mod|struct|enum|impl)/) {
      return $1;
    }
  }
  say "Something wrong with header: $text";
  exit 1;
}

# (level, text, mode) where mode in {struct fn enum mod normal impl}
sub parse_header {
  $_ =~ /^\s*(\#{1,6}) (.*)/;
  my $level = length $1;
  my $text  = $2;
  my $mode  = is_special_header($text)
    ? special_header_type($text)
    : 'normal';
  ($level, $text, $mode);
}

my $nest_level = 0;
my @opened_blocks = ();
sub open_block {
  say '{';
  $nest_level += 1;
}
sub close_block {
  say "}";
  
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
  exit 0;
}

my $prev_header_level = 0;
my $curr_header_level = 0;
my $prev_mode = 'normal';
my $curr_mode = 'normal';

while (<STDIN>) {
  my $type = line_type $_;
  if ($type eq 'bullet') {
    my ($line, $res) = parse_bulleted_list_for_fn($_);
    say $res;
    print $line;
  }

  elsif ($type eq 'header') {
    $prev_header_level = $curr_header_level;
    $prev_mode = $curr_mode;
    my ($new_header_level, $header_text, $new_mode) = parse_header $_;
    $curr_header_level = $new_header_level;
    $curr_mode = $new_mode;
    say "he $header_text sets l $curr_header_level from $prev_header_level" .
      " and also m $curr_mode from $prev_mode";
    # TODO: fix so it works properly!!
    $curr_header_level <= $prev_header_level and $curr_mode ne 'normal' ? close_block : open_block;
  }

  else {
    print ((' ' x ($indent_size * $nest_level)) . "$type  $_") unless $curr_mode eq 'normal';
  }
}

