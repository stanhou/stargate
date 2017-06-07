#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use IO::Compress::Gzip qw(gzip $GzipError);
use Math::Complex;

use Getopt::Long qw(GetOptionsFromString);
use Getopt::Long qw(GetOptionsFromArray);
use Getopt::Long qw(:config no_ignore_case);
use Getopt::Long qw(:config pass_through);
use Term::ANSIColor qw (:constants);
use File::Basename;
use threads;
use threads::shared;
use Thread::Semaphore;
use Cwd;

my $help      = 0;         #show help
my $ip        = 0;         #kind of rules 
my $vpn       = 0;         #vpn or not 
my $size      = 1;         #size of database 
my $name      = "lpm";   #name of output file 

use constant USAGE => <<'HERE';
    -----------------------------------------------------------------------------
    # REVISION LOG
    #-----------------------------------------------------------------------------
    2017/03/24     V0.1      Initial Version
    
    -----------------------------------------------------------------------------
    # Usage
    -----------------------------------------------------------------------------
    OPTION          |DEFAULT  |DESCRIPTION    -h|help          off       Print help information. <CMD>
    -h|help          off       Print help information. <CMD>
    -ip              0         IPv4 or IPv6, default IPv4
    -vpn             off       Whether to add VPN or not, default not 
    -s|size          1         Data size, base unit K, default 1K
    -n|name <>       lpm       Data file name, default is lpm.in

    -----------------------------------------------------------------------------
    # EXAMPLES
    -----------------------------------------------------------------------------
    (1). Produce 4K rules for IPv4 with VPN 
    >> ./lpm_gen.pl -vpn -s 4 
HERE

#################################################################################
## GetOption
#################################################################################
GetOptions(
    "h|help"       => \$help,
    "ip"           => \$ip,
    "vpn"          => \$vpn,
    "s|size=i"     => \$size,
    "name=s"       => \$name,
);
die USAGE if $help;

#################################################################################
## Parse Options
#################################################################################
my $rec_num;
my $ip_sec;
my $mask_num;
if( -e "${name}.in") {
   unlink "${name}.in";
}
open my $fp_ip,">","${name}.txt" or die "Unable to open ${name}.txt\n";
# add ${name}_data.txt and ${name}_mask.txt to store data string for nseApp use
open my $fp_data,">","${name}_data.txt" or die "Unable to open ${name}_data.txt\n";
open my $fp_mask,">","${name}_mask.txt" or die "Unable to open ${name}_mask.txt\n";

print "Produce ".($ip ? "IPv6 " : "IPv4 ")."records ".($vpn ? "with " : "without ")."VPN Begin\n";

print "check size $size, ip $ip and name $name, vpn $vpn\n";
my %hs;
my $numl;
my $numm;
my $numh;
for ($rec_num = 0; $rec_num <= $size*1024-1; $rec_num++) {
    my $recf;
    my $recf_data;
    my $recf_mask;
    if($ip eq 0) {   #IPv4
        $mask_num = int(rand(33));
        if($vpn eq 0) {    #without VRF
            for(my $par=0; $par<32; $par++) {
                $ip_sec = ($par eq 7 or $par eq 30) ? 1 : int(rand(2));
                if($par < (32-$mask_num)) {
                    $recf = $recf.$ip_sec;
                    $recf_data = $recf_data.$ip_sec;
                    $recf_mask = $recf_mask."0";
                }
                else {
                    $recf = $recf."X"; 
                    $recf_data = $recf_data."0";
                    $recf_mask = $recf_mask."1";
                }
            }
			
            # If the rule is already exist, recalculate a new one
            while($hs{$recf}) {
                $recf = '';
                $recf_data = '';
                $recf_mask = '';
                $mask_num = int(rand(33));
                for(my $par=0; $par<32; $par++) {
                    $ip_sec = ($par eq 7 or $par eq 30) ? 1 : int(rand(2));
                    if($par < (32-$mask_num)) {
                        $recf = $recf.$ip_sec;
                        $recf_data = $recf_data.$ip_sec;
                        $recf_mask = $recf_mask."0";
                    }
                    else {
                        $recf = $recf."X"; 
                        $recf_data = $recf_data."0";
                        $recf_mask = $recf_mask."1";
                    }
                }
                #print "identical and repeat\n";
            }
            $hs{$recf}++;
            print $fp_ip $recf;
            print $fp_ip "X" x 112;
            print $fp_data $recf_data;
            print $fp_data "0" x 112;
            print $fp_mask $recf_mask;
            print $fp_mask "1" x 112;
        }
        else {
            for(my $par=0; $par<48; $par++) {
                $ip_sec = ($par eq 7 or $par eq 30) ? 1 : int(rand(2));
                if($par < (48-$mask_num)) {
                    $recf = $recf.$ip_sec;
                }
                else {
                    $recf = $recf."X"; 
                }
            }
			
            # If the rule is already exist, recalculate a new one
            while($hs{$recf}) {
                $recf = '';
                $mask_num = int(rand(33));
                for(my $par=0; $par<48; $par++) {
                    $ip_sec = ($par eq 7 or $par eq 30) ? 1 : int(rand(2));
                    if($par < (48-$mask_num)) {
                        $recf = $recf.$ip_sec;
                    }
                    else {
                        $recf = $recf."X"; 
                    }
                }
                #print "identical and repeat\n";
            }
            $hs{$recf}++;
            print $fp_ip $recf;
            print $fp_ip "X" x 96;
        }
        printf $fp_ip ("\,%06X\n", $rec_num);
        printf $fp_data ("\,%06X\n", $rec_num);
        printf $fp_mask ("\,%06X\n", $rec_num);
    }
    else {    # IPv6
        $mask_num = int(rand(129));
        if($vpn eq 0) {
            for(my $par=0; $par<128; $par++) {
                $ip_sec = int(rand(2));
                if($par < (128-$mask_num)) {
                    $recf = $recf.$ip_sec;
                } else {
                    $recf = $recf."X";
                }
            }
			
            # If the rule is already exist, recalculate a new one
            while($hs{$recf}) {
                $recf = '';
                $mask_num = int(rand(129));
                for(my $par=0; $par<128; $par++) {
                    $ip_sec = int(rand(2));
                    if($par < (128-$mask_num)) {
                        $recf = $recf.$ip_sec;
                    }
                    else {
                        $recf = $recf."X"; 
                    }
                }
                #print "identical and repeat\n";
            }
            $hs{$recf}++;
            print $fp_ip $recf;
            if($mask_num > 95) {
                $numl++;
            } elsif($mask_num<=95 && $mask_num>31) {
                $numm++;
            } else {
                $numh++;
            }
            print $fp_ip "X" x 16;
        } else {
            for(my $par=0; $par<144; $par++) {
                $ip_sec = int(rand(2));
                if($par < (144-$mask_num)) {
                    $recf = $recf.$ip_sec;
                } else {
                    $recf = $recf."X";
                }
            }
			
            # If the rule is already exist, recalculate a new one
            while($hs{$recf}) {
                $recf = '';
                $mask_num = int(rand(129));
                for(my $par=0; $par<144; $par++) {
                    $ip_sec = int(rand(2));
                    if($par < (144-$mask_num)) {
                        $recf = $recf.$ip_sec;
                    }
                    else {
                        $recf = $recf."X"; 
                    }
                }
                #print "identical and repeat\n";
            }
            $hs{$recf}++;
            print $fp_ip $recf;
        }
        printf $fp_ip ("\,%06X\n", $rec_num);
    }
} # rec_num
printf ("None-X less than 32 is %d, between 32 and 96 is %d, larger than 96 is %d\n", $numl, $numm, $numh);

print "---------------------- END of Production --------------------------------------------\n";
