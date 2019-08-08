#!/usr/bin/perl
use 5.010;
# use strict; 
use warnings;
use experimental qw( switch );

sub ApplyNumberedList {
  my (%obj, $line) = @_;
  given ($obj{'type'}) {
    when('fn') {
      $obj{'header3'} .= parse_numbered_list_for_fn $line }
    default {}
  }
  %obj;
}

sub ApplyQuote {
  my (%obj, $line) = @_;
  $obj{'prologue'} .= parse_quote $line;
  %obj;
}

sub ApplyCodelet {
  my (%obj, $line) = @_;
  $obj{'body'} .= parse_codelet $line;
  %obj;
}

sub AsString {
  my %obj = @_;
  "$obj{'prologue'}$obj->{'header1'} $obj->{'header2'} $obj->{'header3'} {\n" .
  "$obj->{'body'}$obj->{'epilogue'}\n}\n";
}
my @doc = ();

sub close_sections {
  my @sections = @{$_[0]};
  foreach my $i (0 .. $#sections - 1) {
    $sections[$i]{'closed?'} = 1 
    if $sections[$i]{'at_nest_lvl'} <= $sections[$i + 1]{'at_nest_lvl'};
  }
  @sections;
}

sub merge_sections {
  my @sections = @_;
  foreach my $i (0 .. $#sections - 1) {
    next unless defined $sections[$i];
    if (!$sections[$i]{'closed?'} and $sections[$i + 1]{'closed?'}) {
      $sections[$i]{'epilogue'} = AsString $sections[$i + 1];
      undef $sections[$i + 1];
    }
  }
  @sections;
}

sub fold_sections {
  # Array is passed by reference, deref it:
  my @sections = @{$_[0]};
  my @buf1 = @sections;
  my @buf2 = @sections;
  do {
    @buf2 = @buf1;
    @buf1 = merge_sections close_sections \@buf1;
  } while ($#buf1 != $#buf2);
  @buf1;
}

# sub print_indent {
#   print ' ' x ($indent_size * $nest_level); }

while (<STDIN>) {
  my $type = line_type $_;
  if ($type eq 'bullet') {
    @doc[-1] = ApplyBulletedList $doc[-1], $_;
  }

  elsif ($type eq 'header') {
    my ($at_nest_lvl, $header, $type) = parse_header $_;
    push @doc, New($type, $header, $at_nest_lvl);
  }
}

push @doc, New('normal', '', 0);
print join '', map(AsString, fold_sections(\@doc));
