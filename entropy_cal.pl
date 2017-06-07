#!/usr/bin/env perl

#
#

use strict;
use warnings;
use utf8;
use Math::Complex;
#printf "log2(1024) = %lf\n", logn(1024, 2); # watch out for argument order!

my $count1;
my $count0;
my $countX;
my $percent0;
my $percent1;
my $percentX;
my $tcount0=0;
my $tcount1=0;
my $tcountX=0;
my $entropy; 
open TX, "<T1.txt" or die "unable to open T1\n";
while(<TX>){
  if(/(.*),(.*)/){
      $count1 = $1 =~ tr/1//;
      $count0 = $1 =~ tr/0//;
      $countX = $1 =~ tr/X//;
      $percent0 = $count0/($count0+$count1+$countX) ;
      $percent1 = $count1/($count0+$count1+$countX) ;
      $percentX = $countX/($count0+$count1+$countX) ;
      $entropy = -($percent0 * logn($percent0,2) + $percent1 * logn($percent1,2)+$percentX * logn($percentX,2));
      printf("%d, %d, %d, %d, %5.2f, %5.2f, %5.2f, %5.2f \n", $count1, $count0, $countX, $count1+$count0+$countX, $percent0*100, $percent1*100, $percentX*100, $entropy);
      $tcount1 = $tcount1 + $count1 ;
      $tcount0 = $tcount0 + $count0 ;
      $tcountX = $tcountX + $countX ;
  }
}
$percent0 = $tcount0/($tcount0+$tcount1+$tcountX) ;
$percent1 = $tcount1/($tcount0+$tcount1+$tcountX) ;
$percentX = $tcountX/($tcount0+$tcount1+$tcountX) ;
$entropy = -($percent0 * logn($percent0,2) + $percent1 * logn($percent1,2)+$percentX * logn($percentX,2));
printf("%d, %d, %d, %d, %5.2f, %5.2f, %5.2f, %5.2f \n", $tcount1, $tcount0, $tcountX, $tcount1+$tcount0+$tcountX, $percent0*100, $percent1*100, $percentX*100, $entropy);
close(TX);
