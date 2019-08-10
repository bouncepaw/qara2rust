#!/usr/bin/perl
use 5.010;
use warnings;
use experimental qw( switch );
use Data::Dumper;

 # This section contains parts important for both modes.

# Only subset of Markdown that is important for Qaraidel is checked.
sub line_type {
  given ($_) {
    when(/^\s*\#{1,6} /)  { 'header' }
    when(/^\s*```/)       { 'fence'  }
    when(/^\s*[\*\-\+] /) { 'bullet' }
    when(/^\s*\d+\. /)    { 'index'  }
    when(/^\s*\> /)       { 'quote'  }
    when(/^\s*$/)         { 'blank'  }
    default               { 'text'   } } }

my $indent_size = 4;
my $should_weave = 0;

foreach (@ARGV) {
  given ($_) {
    when(/^-h|--help/) {
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
      exit 0; }
    when(/^--indent=([0-9]*)/) { $indent_size = $1; }
    when(/^--doc|--weave/)     { $should_weave = 1; }
    default                    { die "Unknown option: $_" } }
  my $opt = $_; 
}
 # This section is about weave mode

if ($should_weave) {
  my $in_codelet = 0;
  my $would_be_nice_to_clean_blank = 0;
  while (<STDIN>) {
    given (line_type $_) {
      when('fence') {
        # Invert state.
        $in_codelet = $in_codelet ? 1 : 0;
        $would_be_nice_to_clean_blank = 1 unless $in_codelet; }
      when('quote') {
        $would_be_nice_to_clean_blank = 1; }
      when('blank') {
        print unless $would_be_nice_to_clean_blank }
      default {
        print } } }
  exit 0;
}

 # Start parsers for headers

# ∀ word, header: word is first in header => header is special.
my %special_header_triggers =
  map { $_ => 1 } ( "pub", "impl", "fn", "mod", "struct", "enum", "unsafe" );

sub header_type {
  my ($text) = @_;
  $text =~ /^([a-z]*) /;
  return 'normal' unless exists $special_header_triggers{$1};

  my @words = split / /, $text;
  foreach (@words) {
    if ($_ =~ /(fn|mod|struct|enum|impl)/) { return $1 }
  }
  die "Something wrong with header: $text";
}

# (nest, text, mode) where mode in {struct fn enum mod normal impl}
sub parse_header {
  $_ =~ /^\s*(\#{1,6}) (.*)/;
  my $nest = length $1;
  my $text = $2;
  my $type = header_type $text;
  ($nest, $text, $type)
}

sub New {
  my ($nest_lvl, $header1, $htype) = @_;
  %obj =
  ( 'prologue' => '',        'epilogue' => '',
    'header1'  => $header1,  'header2'  => '',
    'header3'  => '',        'type'     => $htype,
    'nest_lvl' => $nest_lvl, 'body'     => '',
    'closed?'  => 0 );
  %obj
}
 # Parsers for codelets

# (line on which parsing ended,
#  result of parsing)
sub parse_codelet {
  my $res = "";

  while (<STDIN>) {
    return ($_, $res) if 'fence' eq line_type $_;
    $res .= $_;
  }
}

sub ApplyCodelet {
  my ($obj_ref, $line) = @_;
  my ($stopline, $res) = parse_codelet $line;
  $obj_ref->{'body'} .= $res;
  $stopline
}
 # Parsers for numbered lists

# Remove index and optional backticks from list item.
sub disindex {
  $_ = /^\s*\d*. \`?([^\`]*)/; $1}

# (line on which parsing ended,
#  result of parsing)
sub parse_numbered_list_for_fn {
  my ($line) = @_;
  my $res = disindex $line;

  while (<STDIN>) {
    $line = $_;
    my $type = line_type $line;
    unless ($type =~ m/index|text/) {
      my @possible_returnees = (" -> $res", " -> ($res)");
      return ($line, $possible_returnees[$res =~ m/\,/ ? 1 : 0]);
    }
    $res .= ', ' . disindex $line if ($type eq 'index');
  }
}

sub ApplyNumberedList {
  my ($obj_ref, $line) = @_;
  if ($obj_ref->{'type'} eq 'fn') {
    my ($stopline, $res) = parse_numbered_list_for_fn $line;
    $obj_ref->{'header3'} = $res;
    return $stopline;
  }
  ''
}

 # parsers for bulletlists

# Remove bullet and optional backticks from list item.
sub disbullet {
  $_ =~ /^\s*[\*\-\+] \`?([^\`]*)/; $1 }

# (line on which parsing ended,
#  result of parsing)
sub parse_bulleted_list_generic {
  my ($commencer, $joiner, $terminator, $first_line) = @_;
  my $res = $commencer . disbullet($first_line);

  while (<STDIN>) {
    my $type = line_type $_;
    return ($_, $res . $terminator) unless $type eq 'bullet' or $type eq 'text';
    $res .= $joiner . disbullet $_ if $type eq 'bullet';
  }
}

sub parse_bulleted_list_for_fn {
  parse_bulleted_list_generic('(', ', ', ')', $_[0]) }
sub parse_bulleted_list_for_struct_or_enum {
  parse_bulleted_list_generic("    ", ",\n    ", "\n", $_[0]) }

sub ApplyBulletedList {
  my ($obj_ref, $line) = @_;
  if ($obj_ref->{'type'} eq 'fn') {
    my ($stopline, $res) = parse_bulleted_list_for_fn $line;
    $obj_ref->{'header2'} .= $res;
    return $stopline;
  }
  elsif ($obj_ref->{'type'} =~ /struct|enum/) {
    my ($stopline, $res) = parse_bulleted_list_for_struct_or_enum $line;
    $obj_ref->{'body'} .= $res;
    return $stopline;
  }
  ''
}

 # Parsers for quotes

sub disquote {
  $_ =~ /^\s*\>\s*(.*$)/; $1 }

sub parse_quote {
  my ($line) = @_;
  my $res = disquote($line) . "\n";

  while (<STDIN>) {
    return ($_, $res) if 'quote' ne line_type $_ ;
    $res .= disquote($_) . "\n";
  }
}

sub ApplyQuote {
  my ($obj_ref, $line) = @_;
  if ($obj_ref->{'type'} ne 'normal') {
    my ($stopline, $res) = parse_quote $line;
    $obj_ref->{'prologue'} = $res;
    return $stopline;
  }
  ''
}

 # Start main part
sub AsString {
  my ($hash_ref) = @_;
  return $hash_ref->{'body'} . $hash_ref->{'epilogue'}
  if ($hash_ref->{'type'} eq 'normal');

  if ($hash_ref->{'type'} eq 'fn' and not $hash_ref->{'header2'}) {
    $hash_ref->{'header2'} = '()'}
  $hash_ref->{'prologue'} . $hash_ref->{'header1'} . $hash_ref->{'header2'}
  . $hash_ref->{'header3'} . " {\n". $hash_ref->{'body'}
  . $hash_ref->{'epilogue'} . "}\n"
}

# First, read everything into array of sections:
my @sections = ();
my $line = '';
while (<STDIN>) {
  my $type = line_type $_;
  if ($type eq 'header') { 
    my %new_section = New parse_header $_;
    push @sections, \%new_section;
  } 
  elsif ($type eq 'index') {
    $line = ApplyNumberedList $sections[-1];
  }
  elsif ($type eq 'bullet') { 
    $line = ApplyBulletedList $sections[-1];
  }
  elsif ($type eq 'fence') {
    $line = ApplyCodelet $sections[-1];
  }
  elsif ($type eq 'quote') {
    $line = ApplyQuote $sections[-1];
  }
  elsif ($type eq 'text' or $type eq 'blank') {}
  else { print "$type	$_" }
}

# Second, push fake section object. It is required by the alcorithm:
my %fake_section = New(0, 'normal', '');
push @sections, \%fake_section;

# Third, declare some tricky functons that will be used later:
sub close_sections {
  my ($sections_ref) = @_;
  # I used < for purpose.
  for ($i = 0; $i < $#$sections_ref; $i++) {
    $sections_ref->[$i]->{'closed?'} = 1 if
    $sections_ref->[$i]->{'nest_lvl'} >= $sections_ref->[$i + 1]->{'nest_lvl'}
  }
}

sub merge_sections {
  my ($sections_ref) = @_;
  my $changed_anything = 0;
  for ($i = 0; $i < $#$sections_ref; $i++) {
    if ($sections_ref->[$i]->{'closed?'} == 0
        and $sections_ref->[$i + 1]->{'closed?'}) {
      $sections_ref->[$i]->{'epilogue'} .= AsString $sections_ref->[$i + 1];
      undef $sections_ref->[$i + 1];
      $i++;
      $changed_anything = 1;
    }
  }
  $changed_anything
}

# Fourth, apply the tricky alcorithm until it's ok:
my $changed_anything = 0;
do {
  close_sections \@sections;
  $changed_anything = merge_sections \@sections;
  @sections = grep defined, @sections;
} while ($changed_anything);

# Fifth, remove the fake sections object as it is not needed anymore:
pop @sections;

# Sixth, join and print everything.
print join '', map({ AsString $_ } @sections)
