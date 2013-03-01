#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use File::Spec;

my $help_string = "Need a source directory with the ch*.txt files, a destination directory\nand the directory with the HTML \"sources\"!\n";
my $orig_dir = shift || die $help_string;
my $dest_dir = shift || die $help_string;
my $html_dir = shift || die $help_string;

opendir D, $orig_dir or die "Can't open directory $orig_dir";
while (my $file = readdir D) {
  next unless $file =~ /^(ch|bi)\d+\.txt$/;

  open F, File::Spec->catfile($orig_dir, $file);
  open F1, ">" . File::Spec->catfile($dest_dir, $file);

  # Tweak for syntax highlighting. Files like "highlighting-ch04.txt"
  # can be used to force a certain language for the syntax
  # highlighting (the first line is the character encoding for the
  # output, and each line after that is for one source code block, in
  # order).
  my @langs;
  open FLANGS, "highlighting-$file" and do {
    @langs = map { chomp; $_ } <FLANGS>;
    close FLANGS;
  };

  my $status = 'header';
  my $source_block_n = 0;
  while (my $line = <F>) {
    if ($status eq 'header') {
      if ($line =~ /^\* \* \*/) {
        $status = 'title';
      }
    }
    elsif ($status eq 'title') {
      if ($line =~ /^#/) {
        $line =~ s/\#//;
        $status = 'print';
      }
      print F1 $line;
    }
    elsif ($status eq 'print') {
      if ($line =~ /^\* \* \*/) {
        $status = 'footer';
      }
      else {
        if ($line =~ /^    $/) {
          while ($line = <F>) {
            if ($line =~ /^_/) {
              my $html_file = File::Spec->catfile($html_dir, $file);
              $html_file =~ s/\.txt/.html/o;
              $source_block_n++;
              my $source_code =
                decode('utf-8', `./get_sources.pl $html_file $source_block_n`);
              $source_code =~ s/^/    /gom;
              my $current_lang = $langs[$source_block_n - 1];
              if ($current_lang) {
                $source_code = qq({:lang="$current_lang"}) . "\n" .
                  $source_code;
              }
              print F1 "\n", encode('utf-8', $source_code);
              last;
            }
          }
        }

        # Fix footnotes
        $line =~ s/\[\[(\d+)\]\(#ftn.idp\d+\)\]/[^$1]/g;
        # Fix bibliography references
        $line =~ s/bi01\.html/(#/g;

        # Add ids to bibliography entries
        if ($file =~ /^bi/) {
          $line =~ s/^\[([^\]]+)\]/{#$1}\n[$1]/;
        }

        print F1 $line;
      }
    }
    elsif ($status eq 'footer') {
      # We collect any footnotes there might be here
      if ($line =~ /^\[\[(\d+)\][^\]]+\] (.+)/) {
        my ($ft_number, $ft_text) = ($1, $2);
        # Fix bibliography references
        $ft_text =~ s/\(bi01\.html#/(#/g;
        print F1 "[^$ft_number]: $ft_text\n\n";
      }
    }
  }
  close F1;
  close F;
}
closedir D;
