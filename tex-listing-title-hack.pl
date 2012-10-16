#!/usr/bin/perl

use strict;
use warnings;

use Encode;

my $file = shift @ARGV;

my $title = "YOU HAVE A BUG, SUCKER";

# Turns stupid code snippet captions from:
#     {\bf Code caption}
#
#     \begin{lstlisting}[...
# to:
#     \begin{lstlisting}[...,title={Code caption}]
#
# Moreover, as the TeX conversion drops links from captions for some
# reason, we try to fish them back by grepping the sources (UGH).

sub find_snippet_url {
  my ($title) = @_;

  $title =~ s/\s+\(.*//;  # remove the filename between parentheses
  for (<../*.asc>) {
    open F2, $_;
    while (my $line = decode("utf-8", <F2>)) {
      if ($line =~ /^\.$title \((.*)\[.*\]\)/) {
        return $1;
      }
    }
    close F2;
  }

  return;
}

open F, $file;
while (my $line = <F>) {
  if ($line =~ /{\\bf (.+)}/) {
    $title = decode("iso-8859-1", $1);
    <F>;         # Discard the next line, should be empty
  } elsif ($title && $line =~ /^\\begin{lstlisting}/) {
    # Try to find the URL for this snippet. If found, add a link.
    my $url = find_snippet_url($title) // "";
    if ($url) {
      $title =~ /(.+) \((.+)\)/;
      my ($human_title, $filename) = ($1, $2);
      $line =~ s/,\]/,title={$human_title (\\href{$url}{$filename})}]/;
    } else {
      $line =~ s/,\]/,title={$title}]/;
    }
    print $line;
    $title = undef;
  } else {
    print $line;
  }
}
close F;
