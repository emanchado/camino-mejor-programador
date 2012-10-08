#!/usr/bin/perl

use strict;
use warnings;

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

  for (<../*.asc>) {
    open F2, $_;
    while (<F2>) {
      if (/^\.([^\[]+)\[$title\]/) {
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
    $title = $1;
    <F>;         # Discard the next line, should be empty
  } elsif ($title && $line =~ /^\\begin{lstlisting}/) {
    # Try to find the URL for this snippet. If found, add a link.
    my $url = find_snippet_url($title);
    if ($url) {
      $line =~ s/,\]/,title={\\href{$url}{$title}}]/;
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
