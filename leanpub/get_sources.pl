#!/usr/bin/perl

use strict;
use warnings;

my $help_string = "Need source and snippet number\n";
my $source = shift || die $help_string;
my $number = shift || die $help_string;

my $state = "seek";
open F, $source or die "Can't open $source";
while (my $line = <F>) {
  if ($line =~ /<pre class="programlisting">/) {
    if (--$number == 0) {
      $state = "print";
    }
  }

  if ($state eq "print") {
    last if $line =~ /^<\/tt><\/pre>/;

    $line =~ s/<[^>]+>//go;
    $line =~ s/&lt;/</go;
    $line =~ s/&gt;/>/go;
    $line =~ s/&quot;/\"/go;
    $line =~ s/&amp;/&/go;
    print $line;
  }
}
close F;
