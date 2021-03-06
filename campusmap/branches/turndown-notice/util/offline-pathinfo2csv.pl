#!/usr/bin/perl
# -----------------------------------------------------------------
# offline-pathinfo2csv.pl -- Convert the path-metadata files generated by
# offline-paths.pl into CSV files suitable for import to appengine.
# Copyright 2010 Michael Kelly (michael@michaelkelly.org)
#
# This program is released under the terms of the GNU General Public
# License as published by the Free Software Foundation, version 2.
#
# Thu Jul 29 03:30:42 EDT 2010
# -----------------------------------------------------------------

use strict;
use warnings;
use English;

sub usage {
    print STDERR "Usage: $0 input_dir\n";
}

my $global_key = 1;

sub parse_file {
    my $file = shift;
    local $INPUT_RECORD_SEPARATOR;
    open(FILE, '<', $file) or die "$!: $file";
    my $data = <FILE>;
    close(FILE);
    #print "file = $file\n";
    #print "data = $data\n";

    my %v = split(/\n|=/, $data);

    $file =~ m{/(\d+)-(\d+)$};
    my ($id0,$id1) = ($1, $2);

    # We should get something like:
    # rect_ymax=4085
    # rect_ymin=3976
    # rect_xmax=5280
    # rect_xmin=4898
    # path_img_rect_ymax=4117
    # path_img_rect_ymin=3944
    # path_img_rect_xmax=5312
    # path_img_rect_xmin=4866
    # dist=464

    # We output:
    # key,id0,id1,x,y,w,h,dist
    my $w = $v{'path_img_rect_xmax'} - $v{'path_img_rect_xmin'};
    my $h = $v{'path_img_rect_ymax'} - $v{'path_img_rect_ymin'};
    print "$global_key,$id0,$id1,$v{'path_img_rect_xmin'},$v{'path_img_rect_ymin'},$w,$h,$v{'dist'}\n";

    $global_key++;
    if (($global_key % 100) == 0) {
        print STDERR "$global_key\n";
    }
}

my $input_dir = shift(@ARGV) or usage();
my @files = glob("$input_dir/*");
#print scalar(@files) . " input files.\n";

print "key,id0,id1,x,y,w,h,dist\n";
for my $f (@files) {
    parse_file($f);
}
