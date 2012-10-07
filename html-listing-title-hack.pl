#!/usr/bin/perl

use strict;
use warnings;

my $file = shift @ARGV;

my ($chop_p, $title) = (1, "YOU HAVE A BUG, SUCKER");

open F, $file;
while (my $line = <F>) {
  if ($line =~ /<p title=/) {
    if ($chop_p) {
      $title = <F>;
      $title =~ s|\...</strong>|</strong>|;
      $title =~ s|<(/?)strong>|<$1em>|g;
      <F>;         # Discard the next line, should be the closing </p>
    } else {
      print $line;
      print $title;
    }
    $chop_p = !$chop_p;
  } else {
    print $line;
  }
}
close F;
