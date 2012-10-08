#!/usr/bin/perl

use strict;
use warnings;

my $file = shift @ARGV;

my $title = "YOU HAVE A BUG, SUCKER";

open F, $file;
while (my $line = <F>) {
  if ($line =~ /^<div class="title">/) {
    $title = $line;
  } elsif ($title && $line =~ m|</pre></div></div>|) {
    $line =~ s|</div>\s*$||;
    print $line;
    print $title;
    print "</div>\n";
    $title = undef;
  } else {
    print $line;
  }
}
close F;
