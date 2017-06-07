#!/usr/bin/env perl

##===============================================================================
#  CRIPTION: Script to run test
#  AUTHOR: Oupeng (peng.ou@corigine.com)
#          Stanly (hexi.hou@corigine.com)
#          James  (jun.wang@corigine.com)
#  CREATED: 01/11/2016 10:31:05 AM
# ===============================================================================

use strict;
use warnings;
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

################################################################################
# Variables
################################################################################
my $help      = 0;         #show help
my $rgs_mode  = 0;         #run full regression
my $section   = "";        #Testplan Section
my $begin     = 1;         #Begin of test case
my $end       = 1;         #End of test case
my $keep_db   = 0;         #Keep the database after test
my $sw_ver    = "release"; #Software Version
my $iter      = 1;         #Number of search for each cases
my $nolegacy  = 0;         #Mode of run_test, legacy or new
my $gen_vid   = 0;         #Vendof ID during IPF generating
my $gen_ipf   = 0;         #Generate IPF
my $gen_tpf   = 0;         #Generate TPF
my $gen_pd    = 0;         #Genarate PD 
my $case_num  = 0;
my $idx       = "";
my $idx_ins   = "";
my $nseed     = -1;

chomp (my $HOSTNAME = `hostname`);
chomp (my $PWD = `pwd`); 
chomp (my $USR = `whoami`);

#"section" => (begin, end)
my %test_range  = (
  "1.1-1"  => [1,98],          #1~25,33~44,48~49,51~59:0.1, 60~69:0.6, 70~98:
  "1.1-2"  => [1,98],          #1~25,33~44,48~49,51~59:0.1, 60~69:0.6, 70~98:
  "1.1-3"  => [1,7],           # By now, only 7 cases run, the others have no info
  "1.1-4"  => [1,25],
  "1.1-5"  => [1,23],
  "1.1-6"  => [1,19],
  "1.1-7"  => [1,42],
  "1.1-8"  => [1,15],
  "1.1-10" => [1,15],
); # end-of-test_range

#The following arrays are defined against my will
my $case_idx_1 = [['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b','c'], ['a','b'],
                  ['a','b'], ['a','b'], ['a','b'] ,['a','b'], ['a','b','c'], [], [], [], [], [],                        # For negetive case, leave the item blank
                  [], [], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a','b'], ['a'], ['a','b','c'], ['a','b'], [], [], [], ['a','b','c','d'], ['a'], [],
                  ['a'], ['a','b','c','d'], ['a','b','c','d','e','f','g','h','i','j'], ['a','b'], ['a','b','c','d','e','f','g','h','i'], [], [], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b'], ['a','b'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['b'], ['a','b'], ['a','b'], ['a','b'], ['a']];
my $case_idx_2 = [['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b','c'], ['a','b'],
                  ['a','b'], ['a','b'], ['a','b'] ,['a','b'], ['a','b','c'], [], [], [], [], [],
                  [], [], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a','b'], ['a'], ['a','b','c'], ['a','b'], [], [], [], ['a','b','c','d'], ['a'], [],
                  ['a'], ['a','b','c','d'], ['a','b','c','d','e','f','g','h','i','j'], ['a','b'], ['a','b','c','d','e','f','g','h','i'], [], [], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'], ['a','b'], ['a','b'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a','b'], ['a','b'],
                  ['a','b'], ['a','b'], ['a'], ['b'], ['a','b'], ['a','b'], ['a','b'], ['a']];                
my $case_idx_3 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'],['a']];
my $case_idx_4 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a']];
my $case_idx_5 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a']];
my $case_idx_6 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a']];
my $case_idx_7 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a']];
my $case_idx_8 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                  ['a'], ['a'], ['a'], ['a'], ['a']];
my $case_idx_10 = [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'],
                   ['a'], ['a'], ['a'], ['a'], ['a']];

my %test_idx = (
  "1.1-1" => $case_idx_1,
  "1.1-2" => $case_idx_2,
  "1.1-3" => $case_idx_3,
  "1.1-4" => $case_idx_4,
  "1.1-5" => $case_idx_5,
  "1.1-6" => $case_idx_6,
  "1.1-7" => $case_idx_7,
  "1.1-8" => $case_idx_8,
  "1.1-10" => $case_idx_10,
);

########################################################################
# REVISION LOG
#########################################################################
use constant USAGE => <<'HERE';
    -----------------------------------------------------------------------------
    # REVISION LOG
    -----------------------------------------------------------------------------
    2016/11/01      V1.001      Initial Version
    
    -----------------------------------------------------------------------------
    # Usage
    -----------------------------------------------------------------------------
    OPTION          |DEFAULT  |DESCRIPTION
    -h|help          off       Print help information. <CMD>
    -r|regress       off       Run full regression
    -s|section <S>   ''        Testplan Section
    -begin           1         Begin test of run
    -end             1         End test of run
    -k|keep          off       Keep the database after test
    -v <S>           release   Software Version
    -iter            1         The number of search requests
    -n|nolegacy      off       Legacy run_test or New run_test
    -gen_vid         0         Vendor ID during generating IPF files
    -gen_ipf         0         Whether to generate IPF files
    -gen_tpf         0         Whether to generate TPF files
    -gen_pd          0         Whether to generate PD files
    -nseed           -1        seed to reproduce cases in new mode

    -----------------------------------------------------------------------------
    # EXAMPLES
    -----------------------------------------------------------------------------
    (1). Run Regression of full tests
    >> run_regression.pl -r
    (2). Run tests 1-10 within testplan section 1.1-5
    >> run_regression.pl -s 1.1-5 -begin 1 -end 10
HERE

#################################################################################
## GetOptions
#################################################################################
GetOptions(
    "h|help"       => \$help,
    "r|regress"    => \$rgs_mode,
    "s|section=s"  => \$section,
    "begin=i"      => \$begin,
    "end=i"        => \$end,
    "k|keep"       => \$keep_db,
    "v=s"          => \$sw_ver,
    "iter"         => \$iter,
    "n|nolegacy"   => \$nolegacy,
    "gen_vid=i"    => \$gen_vid,
    "gen_ipf"      => \$gen_ipf,
    "gen_tpf"      => \$gen_tpf,
    "gen_pd"       => \$gen_pd,
    "nseed=i"      => \$nseed,
);

die USAGE if $help;

#################################################################################
## Parse Options
#################################################################################

if (!$rgs_mode) {
  if (!exists($test_range{$section})) {
    print"Illegal Test Plan Section\n";
    exit 0;
  }
  elsif (($begin < $test_range{$section}->[0]) 
  || ($end > $test_range{$section}->[1])) {
    print"Illegal Test Range\n";
    exit 0;
  }
  %test_range = ();
  $test_range{$section} = [$begin,$end]; #only one section
}

my $HomePath = "/prjtcam/TestRUN";
#my $LibPath = "/prjtcam/TestRUN/lib/".$sw_ver;
my $LibPath = "/work/hhou/SW_DualPort2/stargate.dev/binaries/Linux/X86/64/debug";
my $SimPath = $LibPath;
my $RptPath = $PWD;

my $DBPath;

################################################################################
## Run Tests
#################################################################################
#
##Link .so library
system"rm -f libgenSearchLib.so";
system"rm -f libplatformLib.so";
system"ln -s ${LibPath}/libgenSearchLib.so libgenSearchLib.so";
system"ln -s ${LibPath}/libplatformLib.so libplatformLib.so";
my $curdir=$PWD;
$ENV{'LD_LIBRARY_PATH'}="$curdir:\$LD_LIBRARY_PATH";

#Prepare Report Dir and Output Log
my $resPathMD;
if (! -e "./Results") {
  system"mkdir Results"
}
if ($nolegacy == 0) {
   if(! -e "./Results/Legacy") {
      system"mkdir ./Results/Legacy";
   }
   $resPathMD="./Results/Legacy"
} else {
   if (! -e "./Results/New") {
      system"mkdir ./Results/New";
   }
   $resPathMD="./Results/New"
}
if (! -e "${resPathMD}/$sw_ver") {
  system"mkdir ${resPathMD}/$sw_ver"
}

open my $fp_rpt,">","${resPathMD}/$sw_ver/test_report.txt" or die "Unable to open test_report.txt\n";
&gen_rpt_header();
if($nolegacy == 0) {
   print $fp_rpt "The results are based on ORIGINAL run_test\n";
} else {
   print $fp_rpt "The results are base on NEW run_test\n";
}
print $fp_rpt "----------------------------------------------------------------------------------\n";

#All test
#foreach $section (sort {$test_range{$a} <=> $test_range{$b}} keys %test_range){
foreach (sort {$test_range{$a} <=> $test_range{$b}} keys %test_range){
  $section = $_;
  $begin = $test_range{$section}->[0];
  $end   = $test_range{$section}->[1];
  if (! -e "${resPathMD}/$sw_ver/$section") {
    system"mkdir ${resPathMD}/$sw_ver/$section"
  }

  if(($section eq '1.1-1') || ($section eq '1.1-2')){
     $DBPath = ${HomePath}."/../TestDB/EnzoTest/TestDB";
  } else {
     $DBPath = ${HomePath}."/../TestDB/NseTest/TestDB";
  }

  if($nolegacy == 0) {
     print $fp_rpt "TestIndex      Status    Notes        Iteration  TimeConsume  SearchNo(Port0)  SearchNo(Port1) \n";
  } else {
     print $fp_rpt "TestIndex      Status    Notes        TimeConsume  Seed\n";
  }
  print $fp_rpt "----------------------------------------------------------------------------------\n";

  for ($case_num = $begin; $case_num <= $end; $case_num++) {
    my @idx_grp = @{$test_idx{$section}};
    foreach $idx (@{$idx_grp[$case_num-1]}){
      print "-> Running Test $section -> $case_num -> $idx\n";
      $idx_ins = $idx;
      print &datetime()."\n";

      #Generate Data Base for Test
      
      #Run Test
      if($nolegacy == 0) {
         &original_run_test();    # Run as original regression
      } else {
         &run_test();             # Run as new regression
      }      
    }#end-of-idx
  }#end-of-case_num
  print $fp_rpt "---------------------- END of Section --------------------------------------------\n";

}#end-of-section

##################################################################
sub datetime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    $year += 1900;
    $mon += 1;
    my $rtn = sprintf ("%d/%02d/%02d-%02d:%02d", $year,$mon,$mday,$hour,$min);
    return $rtn;
}
##################################################################
sub gen_rpt_header {
  print $fp_rpt "**********************************************************************************\n";
  print $fp_rpt "DATE:                ".&datetime()."\n";
  print $fp_rpt "Software Version:    $sw_ver\n";
  if ($rgs_mode) {
    print $fp_rpt "Regression Mode\n";
  }
  else {
    print $fp_rpt "Testplan Section:    $section\n";
    print $fp_rpt "Begin of Test:       $begin\n";
    print $fp_rpt "End of Test:         $end\n";
    print $fp_rpt "**********************************************************************************\n";
  }
}
##################################################################
sub original_run_test {
  my $numOfTables  = 0;
  my $numOfTables2 = 0;
  my @tableEnt     = ();
  my @tableEnt2    = ();
  my $numOfAds     = 0;
  my $numOfAds2    = 0;
  my @adEnt        = ();
  my @adEnt2       = ();
  my @tableEle;
  my @Tname;
  my @Tstep;
  my @Tstart;
  my @Tend;
  my @adEle;
  my @ADname;
  my @ADstep;
  my @ADstart;
  my @ADend;
  my @Tstart_tcam;
  my @Tend_next;
  my @Tstep_tcam;
  my @Tend_tcam;
  my $squidT;
  my @squidTE;
  my $delims;
  my $section_ph;
  my $case_num_ph;
  my $info_line;
  my @info_ele;

  my $RunPath=`pwd`;

  open TEST_LOG, ">", "${resPathMD}/${sw_ver}/${section}/test_${case_num}_${idx_ins}.txt" or die "Unable to open test_${case_num}_${idx_ins}.txt\n";
  &sim_dir();
  printf $fp_rpt "%-6s-%-2d-%-5s", $section, $case_num, $idx_ins;
  print TEST_LOG "Run Command is:\n";
  print TEST_LOG "./run_regression.pl -v $sw_ver -s $section -begin $case_num -end $case_num \n\n";  

  # runCmd.sh is used to store nseLibTest command in SquidSim/ for each case
  #open RunCmd, ">", "${resPathMD}/${sw_ver}/${section}/${case_num}/${idx_ins}/SquidSim/runCmd.sh" or die "Unable to open runCmd.sh\n";
  open RunCmd, ">", "runCmd.sh" or die "Unable to open runCmd.sh\n";

  unlink "bin2ilk";
  unlink "bin2pd";
  unlink "bin2tpf";
  unlink "nseLibTest";

  symlink "${LibPath}/bin2ilk",    'bin2ilk'     or warn "can't symlink to bin2ilk";
  symlink "${LibPath}/bin2pd",     'bin2pd'      or warn "can't symlink to bin2pd";   
  symlink "${LibPath}/bin2tpf",    'bin2tpf'     or warn "can't symlink to bin2tpf";   
  symlink "${LibPath}/nseLibTest", 'nseLibTest'  or warn "can't symlink to nseLibTest";   
  # Database switch when $section is 1.1-1 or 1.1-2, corresponds to EnzoTest
  if ($section eq '1.1-1' || $section eq '1.1-2') {
    if ($case_num <= 59) { 
       $section_ph = '0.1';
       $case_num_ph = $case_num;
    } elsif (($case_num >= 60) && ($case_num <= 69)) {
       $section_ph = '0.6';
       $case_num_ph = $case_num - 59;
    } else {
       $section_ph = '0.7';
       $case_num_ph = $case_num - 69;
    }
  } else {
    $section_ph = $section;
    $case_num_ph = $case_num;
  } 

  #Check whether there are database for scenarios
  if (! -e "${DBPath}/profile${section_ph}/profile${case_num_ph}.$idx_ins.in" ){
     print "Case $case_num_ph Missing Database and Should be Ignored!\n";
     print TEST_LOG "Case $case_num_ph Missing Database and Should be Ignored\n";
     print $fp_rpt "FAIL!!    No Database  --         --           --               --            \n";
     goto EndofTest;
  }

  #Calculate No. T in tablex.a/b/c.in, & read content of tablex.*.in and store in @tableEnt with each item corresponds to a line
  if($section_ph eq '0.7') {
     open TABLE, "<${DBPath}/table${section_ph}/tablet${case_num_ph}.$idx_ins.in" or die "Unable to open table\n";
  } elsif ($section_ph eq '0.6' || ($section_ph eq '0.1' && $case_num_ph eq 48 && $idx_ins eq 'd')){
     open TABLE, "<${DBPath}/table${section_ph}/tables${case_num_ph}.$idx_ins.in" or die "Unable to open table\n";
  } else {
     open TABLE, "<${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in" or die "Unable to open table\n";
  }
  while(<TABLE>) { 
     $numOfTables++ if /T/; 
     push @tableEnt, $_;
  }
  close (TABLE);

  if(-e "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.2.in"){
    open TABLE2, "<${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.2.in" or die "Unable to open table2\n";
    while(<TABLE2>) { 
       $numOfTables2++ if /T/;
       push @tableEnt2, $_;
    }
    close (TABLE2);
  }

  #Calculate No. AD in adx.a/b/c.in, & read content of adx.*.in and store in @adEnt with each item correspond to a line
  if(-e "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.in"){
    open AD, "<${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.in" or die "Unable to open AD\n";
    while(<AD>) { 
       $numOfAds++ if /AD/; 
       push @adEnt, $_;
    }
    close (AD);
  }
  if(-e "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.2.in"){
    open AD2, "<${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.2.in" or die "Unable to open AD2\n";
    while(<AD2>) { 
       $numOfAds2++ if /AD/;
       push @adEnt2, $_;
    }
    close (AD2);
  }

  #Split each item of @tableEnt with (,) and read out Tname/Tstep/Tstart/Tend information
  for(my $j=0; $j<$numOfTables+$numOfTables2; $j++){
    if($j<$numOfTables){
      @tableEle=split(/,/,$tableEnt[$j]);
    } else {
      @tableEle=split(/,/,$tableEnt2[$j-$numOfTables]);
    }
    $Tname[$j] = $tableEle[0];
    $Tstep[$j] = $tableEle[1];
    if(substr($Tstep[$j],length($Tstep[$j])-1,1) eq 'K'){
      $Tstep[$j] = substr($Tstep[$j],0,-1)*1024;
    }
    $Tstart[$j] = 1;
    $Tend[$j] = $Tstart[$j]+$Tstep[$j]-1;
    
    #Tstart_tcam, Tend_tcam, Tstep_tcam calculate for 0.1 and 0.6
    if($section_ph eq '0.6' || ($section_ph eq '0.1' && $case_num_ph == 48 && $idx_ins eq 'd') || ($section_ph eq '1.1-3' && $case_num_ph == 4)) {
       $Tstart_tcam[$j] = 1;
       $Tend_next[$j]   = $Tend[$j] + 1;
       if($section_ph eq '1.1-3') {
          open(SQUID_T, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in squid";
          open(TCAM_T, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in tcam";
       } elsif ($section_ph eq '0.6') {
          open(SQUID_T, "zcat ${DBPath}/data${section_ph}/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in squid";
          open(TCAM_T, "zcat ${DBPath}/data${section_ph}/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in tcam";
       } else {
          open(SQUID_T, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in squid";
          open(TCAM_T, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt in tcam";
       }
       while(<SQUID_T>) {
         $squidT=$_ if($.==$Tend_next[$j]);
       }
       @squidTE=split(/,/,$squidT);
       $delims=$squidTE[1];
       chomp($delims);
       while(<TCAM_T>) {
         last if ($_ =~ /\,$delims/);        # FFFIXXXXme  
         $Tend_tcam[$j]++;
       }
       $Tstep_tcam[$j]=$Tend_tcam[$j]-$Tstart_tcam[$j]+1;
       close(SQUID_T);
       close(TCAM_T);
    }
  }
  for(my $j=0; $j<$numOfAds+$numOfAds2; $j++){
    if($j<$numOfAds){
      @adEle=split(/,/,$adEnt[$j]);
    } else {
      @adEle=split(/,/,$adEnt2[$j-$numOfAds]);
    }
    $ADname[$j]  = $adEle[0];
    $ADstart[$j] = $adEle[2]+1;
    $ADstep[$j]  = $adEle[3]; 
    chomp($ADstep[$j]);   # last element of the row
    if(substr($ADstep[$j],length($ADstep[$j])-1,1) eq 'K'){    #last element takes more space
       $ADstep[$j] = substr($ADstep[$j],0,-1)*1024;
    }
    $ADend[$j] = $ADstart[$j]+$ADstep[$j]-1;
  }

  #Use softlink to link table.in/profile.in/ad.in/info.in/table_tcam.in in TestDB
  #&link_db();
  unlink 'profile.in'; # When rerun case, link should be removed otherwise this will cause link issue 
  unlink 'info.in';
  unlink 'table.in';
  unlink 'table_tcam.in';
  symlink "${DBPath}/profile${section_ph}/profile${case_num_ph}.$idx_ins.in", 'profile.in'     or warn "can't symlink to profile.in";
  if($section_ph eq '0.7') {
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/b/info.txt", 'info.in'                or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/tablet${case_num_ph}.$idx_ins.in", 'table_tcam.in'  or warn "can't symlink to table_tcam.in"; 
     symlink "${DBPath}/table${section_ph}/tables${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
  } elsif ($section_ph eq '0.6') {
     symlink "${DBPath}/data${section_ph}/tcam/info.txt", 'info.in'                    or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/tables${case_num_ph}.$idx_ins.in", 'table.in'  or warn "can't symlink to table.in";
  } elsif ($section_ph eq '0.1' && $case_num_ph == 48 && $idx_ins eq 'd') {
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/b/tcam/info.txt", 'info.in'      or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/tables${case_num_ph}.$idx_ins.in", 'table.in'  or warn "can't symlink to table.in";
  } elsif ($section_ph eq '0.1' && ($case_num_ph == 49 || $case_num_ph == 52)) {
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/a/info.txt", 'info.in'               or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table_tcam.in'  or warn "can't symlink to table_tcam.in"; 
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
  } elsif ($section_ph eq '0.1') {
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/b/info.txt", 'info.in'               or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table_tcam.in'  or warn "can't symlink to table_tcam.in"; 
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
  } elsif ($section_ph eq '1.1-3' && $case_num_ph == 4) {
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/tcam/info.txt", 'info.in'            or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
  } elsif ($section_ph eq '1.1-3') {
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/${idx_ins}/info.txt", 'info.in'      or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table_tcam.in'  or warn "can't symlink to table_tcam.in";
  } else {
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table.in'       or warn "can't symlink to table.in";
     symlink "${DBPath}/data${section_ph}/${case_num_ph}/a/info.in", 'info.in'       or warn "can't symlink to info.in";
     symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.in", 'table_tcam.in'  or warn "can't symlink to table_tcam.in";
  }

  if($section_ph eq '1.1-3' && $case_num_ph == 5) {
     symlink "${DBPath}/profile${section_ph}/profile${case_num_ph}.$idx_ins.xml", 'profile.xml'              or warn "can't symlink to profile.xml";
     symlink "${DBPath}/profile${section_ph}/profile${case_num_ph}.$idx_ins.2.xml", 'profile2.xml'           or warn "can't symlink to profile2.xml";
     symlink "${DBPath}/profile${section_ph}/search_qtcam${case_num_ph}.$idx_ins.in", 'search_qtcam.in'      or warn "can't symlink to search_qtcam.in";
     symlink "${DBPath}/profile${section_ph}/search_qtcam${case_num_ph}.$idx_ins.2.in", 'search_qtcam2.in'   or warn "can't symlink to search_qtcam2.in";
     symlink "${DBPath}/profile${section_ph}/search_online${case_num_ph}.$idx_ins.in", 'search_online.in'    or warn "can't symlink to search_online.in";
     symlink "${DBPath}/profile${section_ph}/search_online${case_num_ph}.$idx_ins.2.in", 'search_online2.in' or warn "can't symlink to search_online2.in";
     symlink "${DBPath}/profile${section_ph}/range${case_num_ph}.$idx_ins.in", 'range.in'       or warn "can't symlink to range.in";
     symlink "${DBPath}/profile${section_ph}/range${case_num_ph}.$idx_ins.2.in", 'range2.in'    or warn "can't symlink to range2.in";
  }

  if(($section_ph eq '1.1-3') || ($section_ph eq '1.1-5') || ($section_ph eq '1.1-8')){
    unlink 'table2.in';
    symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.2.in", 'table2.in'       or warn "can't symlink to table2.in";
    unlink 'profile2.in'; 
    symlink "${DBPath}/profile${section_ph}/profile${case_num_ph}.${idx_ins}.2.in", 'profile2.in' or warn "can't symlink to profile2.in";
    unlink 'info2.in';
    if($section_ph eq '1.1-3' && $case_num_ph == 4) {
      symlink "${DBPath}/data${section_ph}/${case_num_ph}/tcam/info2.txt", 'info2.in'       or warn "can't symlink to info2.in";
    } else {
      if($section_ph eq '1.1-3') {
         symlink "${DBPath}/data${section_ph}/${case_num_ph}/a/info2.txt", 'info2.in'       or warn "can't symlink to info2.in";
      } else {
         symlink "${DBPath}/data${section_ph}/${case_num_ph}/a/info2.in", 'info2.in'       or warn "can't symlink to info2.in";
      }
      unlink 'table2_tcam.in';
      symlink "${DBPath}/table${section_ph}/table${case_num_ph}.$idx_ins.2.in", 'table2_tcam.in'  or warn "can't symlink to table2_tcam.in";
    }
  }

  if(-e "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.in"){
    unlink 'ad.in';
    symlink "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.in", 'ad.in'             or warn "can't symlink to ad.in";
  }
  if(-e "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.2.in"){
    unlink 'ad2.in';
    symlink "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.2.in", 'ad2.in'             or warn "can't symlink to ad2.in";
  }


  if($section_ph eq '1.1-3' && $case_num_ph ==4) {
     open(tTCAM, ">table_tcam.in") or warn "Unable to open table_tcam.in\n";
     open(tTCAM2, ">table2_tcam.in") or warn "Unable to open table2_tcam.in\n";
  } elsif ($section_ph eq '0.6' || ($section_ph eq '0.1' && $case_num_ph==48 && $idx_ins eq 'd')) {
     open(tTCAM, ">table_tcam.in") or warn "Unable to open table_tcam.in\n";
  }

  #Read out big data Tx.txt and select certain lines which will be used in search
  for(my $j=0; $j<$numOfTables+$numOfTables2; $j++){
    # For Tname.txt
    if($section_ph eq '0.6') {
       open(TDATA, "zcat ${DBPath}/data${section_ph}/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    } elsif ($section_ph eq '0.1' && $case_num_ph == 48 && $idx_ins eq 'd') {
       open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    } elsif ($section_ph eq '0.1' && ($case_num_ph == 49 || $case_num_ph == 52)) {
       open(TDATA, "cat ${DBPath}/data${section_ph}/${case_num_ph}/a/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    } elsif ($section_ph eq '0.7' || $section_ph eq '0.1') {
       open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    } elsif ($section_ph eq '1.1-3' && $case_num_ph == 4) {
       open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/squid/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    } else {
       open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/${idx_ins}/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
    }
    open(TD, ">${Tname[$j]}.txt") or die "Unable to open local Tx.txt";
    while(<TDATA>) {
      if($.==$Tstart[$j]..$.==$Tend[$j]){
        print TD $_;
      }
    }
    close(TDATA);
    close(TD);
	
    &entropy_cal("${Tname[$j]}.txt");

    # For Tname_tcam.txt
    if($section_ph eq '0.6' || ($section_ph eq '0.1' && $case_num_ph == 48 && $idx_ins eq 'd') || ($section_ph eq '1.1-3' && $case_num_ph == 4)) {
       unlink "${Tname[$j]}_array.txt";
       if($section_ph eq '1.1-3' && $case_num_ph == 4) {
         open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
         open(TARRAY, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/tcam/${Tname[$j]}_array.txt" ."|") or warn "Unable to open Tx_array.txt";
       } elsif($section_ph eq '0.6') {
         open(TDATA, "zcat ${DBPath}/data${section_ph}/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
         open(TARRAY, "zcat ${DBPath}/data${section_ph}/tcam/${Tname[$j]}_array.txt" ."|") or warn "Unable to open Tx_array.txt";
       } else {
         open(TDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
         open(TARRAY, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/b/tcam/${Tname[$j]}_array.txt" ."|") or warn "Unable to Tx_array.txt";
       }
       open(TCD, ">${Tname[$j]}_tcam.txt") or die "Unable to open local Tx_tcam.txt";
       while(<TDATA>) {
          if($.==$Tstart_tcam[$j]..$.==$Tend_tcam[$j]){
             print TCD $_;
          }
       }
       open(TARRAYD, ">${Tname[$j]}_array.txt") or warn "Unable to open local Tx_array.txt";
       while(<TARRAY>) {
          print TARRAYD $_;
       }
       close(TCD);
       close(TARRAYD);
    } elsif ($section_ph eq '0.1' && ($case_num_ph == 49 || $case_num_ph == 52)) {
       open(TDATA, "cat ${DBPath}/data${section_ph}/${case_num_ph}/a/tcam/${Tname[$j]}.txt" ."|") or die "Unable to open Tx.txt";
       open(TCD, ">${Tname[$j]}_tcam.txt") or die "Unable to open local Tx_tcam.txt";
       while(<TDATA>) {
          if($.==$Tstart[$j]..$.==$Tend[$j]){
             print TCD $_;
          }
       }
       close(TCD);
    } else {
       unlink "${Tname[$j]}_tcam.txt";
       symlink "${Tname[$j]}.txt", "${Tname[$j]}_tcam.txt" or warn "can't symlink to Tx_tcam.txt";
    }
    close(TDATA);
    close(TCD);

    # For table_tcam.in and table2_tcam.in in 1.1-3-4
    # For table_tcam.in in 0.1-48-d and 0.6-x
    if(($section_ph eq '1.1-3' && $case_num_ph == 4) || ($section_ph eq '0.6') || ($section_ph eq '0.1' && $case_num_ph == 48 && $idx_ins eq 'd')) {
       open(TINFO, ($j<$numOfTables) ? "<info.in" : "<info2.in") or die "Unable to open infox.in\n";
       while(<TINFO>) {
         $info_line=$_ if /${Tname[$j]},/ ;
       }
       @info_ele=split(/,/,$info_line);
       if($j < $numOfTables) {
          print tTCAM "${Tname[$j]},${Tstep_tcam[$j]},$info_ele[2],OFFLINE\n";
       } else {
          print tTCAM2 "${Tname[$j]},${Tstep_tcam[$j]},$info_ele[2],OFFLINE\n";
       }
       close(TINFO);
    }
  }
  printf TEST_LOG "\n";

  #Read out big data ADx.txt and select certain lines which will be used in search
  for(my $j=0; $j<$numOfAds+$numOfAds2; $j++){
    open(ADDATA, "zcat ${DBPath}/data${section_ph}/${case_num_ph}/${idx_ins}/${ADname[$j]}.txt" ."|") or die "Unable to open ADx.txt";
    open(ADD, ">${ADname[$j]}.txt") or die "Unable to open local ADx.txt";
    while(<ADDATA>) {
      if($.==$ADstart[$j]..$.==$ADend[$j]){
        print ADD $_;
      }
    }
    close(ADDATA);
    close(TD);
  }
  
  my $number=$iter;
  my $starttime=time;
  print TEST_LOG "Starting time: ".&datetime()."\n";

  #Run nseLibTest with option
  print "Start to run case using nseLibTest\n";
  if($section_ph eq '1.1-3'){
     if($case_num_ph == 5) {
        system"./nseLibTest -dual 3 -gen 0 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -gen 0";
     } else {
        system"./nseLibTest -dual 3 -l $number | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -l $number";
     }
  } elsif ($section_ph eq "1.1-4") {
     if ($case_num_ph == 11 ) {
        system"./nseLibTest -dual 0 -l $number -response 1 -f 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number -response 1 -f 1";
     } elsif ( $case_num_ph == 26 ) {
        system"./nseLibTest -dual 0 -l $number -response 1 -f 3 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number -response 1 -f 3";
     } elsif ( $case_num_ph == 5 ) {
        system"./nseLibTest -dual 0 -l $number -response 1 -r 3 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number -response 1 -r 3";
     } else {
        system"./nseLibTest -dual 0 -l $number -response 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number -response 1";
     }
  } elsif ($section_ph eq "1.1-5") {
     if ($case_num_ph == 5 ) {
        system"./nseLibTest -dual 3 -l $number -response 1 -r 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -l $number -response 1 -r 1";
     } elsif ( $case_num_ph == 24 ) {
        system"./nseLibTest -dual 3 -l $number -response 1 -f 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -l $number -response 1 -f 1";
     } elsif ( $case_num_ph == 25 ) {
        system"./nseLibTest -dual 3 -l $number -response 1 -r 3 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -l $number -response 1 -r 3";
     } else {
        system"./nseLibTest -dual 3 -l $number -response 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 3 -l $number -response 1";
     }
  } elsif ($section_ph eq "1.1-6") {
     system"./nseLibTest -dual 0 -l $number -response 1 -o 6 | tr -d '\b\r' > nseLib.log";
     print RunCmd "nseLibTest -dual 0 -l $number -response 1 -o 6";
  } elsif ($section_ph eq "1.1-7") {
     if (($case_num_ph >= 25) && ($case_num_ph <= 36) ) {
        system"./nseLibTest -dual 0 -l $number -on 1 -o 1 | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number -on 1 -o 1";
     } else {
        system"./nseLibTest -dual 0 -l $number | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number";
     }
  } elsif ($section_ph eq "1.1-8") {
     system"./nseLibTest -dual 3 -l $number | tr -d '\b\r' > nseLib.log";
     print RunCmd "nseLibTest -dual 3 -l $number";
  } elsif ($section_ph eq "1.1-10") {
     if (-f "${DBPath}/table${section_ph}/ad${case_num_ph}.$idx_ins.in") {
        if ($case_num_ph == 15 ) {
           system"./nseLibTest -dual 0 -o 6 -l $number -response 1 -f 1 | tr -d '\b\r' > nseLib.log";
           print RunCmd "nseLibTest -dual 0 -o 6 -l $number -response 1 -f 1";
        } elsif ( $case_num_ph == 16 ) {
           system"./nseLibTest -dual 0 -o 6 -l $number -response 1 -r 1 | tr -d '\b\r' > nseLib.log";
           print RunCmd "nseLibTest -dual 0 -o 6 -l $number -response 1 -r 1";
        } elsif ( $case_num_ph == 17 ) {
           system"./nseLibTest -dual 0 -o 6 -l $number -response 1 -f 2 | tr -d '\b\r' > nseLib.log";
           print RunCmd "nseLibTest -dual 0 -o 6 -l $number -response 1 -f 2";
        } elsif ( $case_num_ph >= 10 ) {
           system"./nseLibTest -dual 0 -o 6 -l $number -response 1 | tr -d '\b\r' > nseLib.log";
           print RunCmd "nseLibTest -dual 0 -o 6 -l $number -response 1";
        } else {
           system"./nseLibTest -dual 0 -l $number -response 1 | tr -d '\b\r' > nseLib.log";
           print RunCmd "nseLibTest -dual 0 -l $number -response 1";
        }
     } else {
        system"./nseLibTest -dual 0 -l $number | tr -d '\b\r' > nseLib.log";
        print RunCmd "nseLibTest -dual 0 -l $number";
     }
  } elsif ($section_ph eq "0.7") {
     if($case_num_ph <= 13) {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -o 1 -l $number -on 1 -cas 1 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -o 1 -l $number -on 1 -cas 1 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -o 1 -l $number -on 1 -cas 1" :
                                print RunCmd "nseLibTest -dual 1 -o 1 -l $number -on 1 -cas 1";
     } else {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -o 8 -l $number -on 1 -lc 0 -cas 1 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -o 8 -l $number -on 1 -lc 0 -cas 1 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -o 8 -l $number -on 1 -lc 0 -cas 1" :
                                print RunCmd "nseLibTest -dual 1 -o 8 -l $number -on 1 -lc 0 -cas 1";
     }
  } elsif ($section_ph eq "0.6") {
     ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -l $number -cas 1 | tr -d '\b\r' > nseLib.log" :
                             system"./nseLibTest -dual 1 -l $number -cas 1 | tr -d '\b\r' > nseLib.log";
     ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -l $number -cas 1" :
                             print RunCmd "nseLibTest -dual 1 -l $number -cas 1";
  } elsif ($section_ph eq "0.1") {
     if($case_num_ph == 48) {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -l $number -r 1 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -l $number -r 1 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -l $number -r 1" :
                                print RunCmd "nseLibTest -dual 1 -l $number -r 1";
     } elsif ($case_num_ph == 53) {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -l $number -cas 1 -f 1 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -l $number -cas 1 -f 1 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -l $number -cas 1 -f 1" :
                                print RunCmd "nseLibTest -dual 1 -l $number -cas 1 -f 1";
     } elsif ($case_num_ph eq 55) {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -l $number -cas 1 -f 2 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -l $number -cas 1 -f 2 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -l $number -cas 1 -f 2" :
                                print RunCmd "nseLibTest -dual 1 -l $number -cas 1 -f 2";
     } elsif ($case_num_ph == 56) {
     } else {
        ($section eq '1.1-1') ? system"./nseLibTest -dual 0 -l $number -cas 1 | tr -d '\b\r' > nseLib.log" :
                                system"./nseLibTest -dual 1 -l $number -cas 1 | tr -d '\b\r' > nseLib.log";
        ($section eq '1.1-1') ? print RunCmd "nseLibTest -dual 0 -l $number -cas 1" :
                                print RunCmd "nseLibTest -dual 1 -l $number -cas 1";
     }
  }

  close(RunCmd);
  my $rccnt = chmod 0755, 'runCmd.sh';
  #Count the LCs in search_qtcam.in and search_online.in
  my $number1=0;
  my $number2=0;
  my $port0Num=0;
  my $port1Num=0;
  open S_QTCAM, "<search_qtcam.in" or warn "Unable to open search_qtcam.in\n";
  while(<S_QTCAM>) { $number1++ if /LC/; }
  close(S_QTCAM);
  open S_ONLINE, "<search_online.in" or warn "Unable to open search_online.in\n";
  while(<S_ONLINE>) { $number2++ if /LC/; }
  close(S_ONLINE);
  $port0Num=$number1+$number2;
  print TEST_LOG "port0Num $port0Num\n"; 
  print "port0Num ${port0Num}\n"; 
  if($section_ph eq '1.1-3'){
    open S_QTCAM, "<search_qtcam2.in" or warn "Unable to open search_qtcam2.in\n";
    while(<S_QTCAM>) { $number1++ if /LC/; }
    close(S_QTCAM);
    open S_ONLINE, "<search_online2.in" or warn "Unable to open search_online2.in\n";
    while(<S_ONLINE>) { $number2++ if /LC/; }
    close(S_ONLINE);
    $port1Num=$number1+$number2;
    print TEST_LOG "port1Num $port1Num\n";
  } 

  #Print out some information in logs 
  my $endtime=time;
  my $diff=$endtime-$starttime;
  print TEST_LOG "Ending time: ".&datetime()."\n";
  print TEST_LOG "Consuming time $diff"."s\n";
  my $result=0;
  my $error=0;
  open nseTestLog, "<nseTest.log" or die "Unable to open nseTest log\n";
  while(<nseTestLog>) { 
    $result++ if /success to run nseLibTest/; 
    $error++ if /ERROR/;
  }
  close (nseTestLog);

  if (($error eq 0) && ($result eq 1)) {
     print TEST_LOG "Passed nseLibTest.\n";
     print "Passed nseLibTest\n";
     print $fp_rpt "Pass      --           ";
     if($gen_pd) {
        system"./bin2pd rtl_out.0.bin";
        if($section eq '1.1-3' || $section eq '1.1-5' || $section eq '1.1-8') {
           system"./bin2pd rtl_out.1.bin";
        }
     } 
     if($gen_ipf) {
        system"./bin2ilk rtl_out.0.bin -v $gen_vid";
        if($section eq '1.1-3' || $section eq '1.1-5' || $section eq '1.1-8') {
           system"./bin2ilk rtl_out.1.bin -v $gen_vid";
        }
     }
     if($gen_tpf) {
       system"./bin2tpf rtl_out.0.bin";
     }
  } else {
     print TEST_LOG "Failed with $error errors.\n";
     print "Failed\n";
     print $fp_rpt "FAIL!!    --           ";
  }
  
  printf $fp_rpt "%-11d%-13d%-17d%-15d\n", $iter, $diff, $port0Num, $port1Num;
  unlink("search_res.txt");

  if(!$keep_db) {
     `find . -name 'T[0-9]*.txt' -type f -delete`;
     `find . -name 'AD[0-9]*.txt' -type f -delete`;
     unlink<T*_tcam.txt>;
     if(-e "search_qtcam.in") {
        gzip "search_qtcam.in" => "search_qtcam.in.gz" or die "gzip failed for search_qtcam\n";
     }
     if(-e "search_tcam.in") {
        gzip "search_tcam.in" => "search_tcam.in.gz" or die "gzip failed for searc_tcam\n";
     }
  }

  EndofTest:
  close(TEST_LOG);
  chdir "../../../../../../..";
} 

# Setup directory for each case to store data and results  
sub sim_dir {
   #unlink "./Results/${sw_ver}/${section}/test_${case_num}_${idx_ins}.txt";

   #mkdir to store results and switch to dirs
   if (! -e "${resPathMD}/$sw_ver/$section/$case_num"){
      system"mkdir ${resPathMD}/$sw_ver/$section/$case_num";
   }
   chdir "${resPathMD}/$sw_ver/$section/$case_num" or die "cannot chdir to case_num";
   if(! -e "./$idx_ins"){
      system"mkdir ./$idx_ins";
   }
   chdir "./$idx_ins" or die "cannot chdir to $idx_ins";
 
   my $resdir="./SquidSim";
   if (! -e "$resdir"){ system"mkdir $resdir"; }
   chdir $resdir;                                     # /home/hhou/TestRUN/Scripts/revB0/Results/svn_now/1.1-4/1/a/SquidSim  
}

# New mode for simulation
sub run_test{
   my $infile;
   my $resultfile;
   my $seed;
   my $RunPath=`pwd`;
   chomp($RunPath);

   my $InfilePath="/work/hhou/run_regression";

   open TEST_LOG, ">", "${resPathMD}/${sw_ver}/${section}/test_${case_num}_${idx_ins}.txt" or die "Unable to open test_${case_num}_${idx_ins}.txt\n";
   &sim_dir();
   printf $fp_rpt "%-6s-%-8d", $section, $case_num;
   print TEST_LOG "Run Command is:\n";

   # Prepare LIBs and Functions for nseLibTest
   # For genRule and ruleParser, at this time, no in common lib
   unlink "bin2ilk";
   unlink "bin2pd";
   unlink "bin2tpf";
   unlink "genRule";
   unlink "libgenRuleLib.so";
   unlink "libgenSearchLib.so";
   unlink "libplatformLib.so";
   unlink "libruleParserLib.so";
   unlink "nseLibTest";
   unlink "ruleParser";
   unlink "run_test.pl";

   symlink "$LibPath/bin2ilk",             'bin2ilk' or warn "can't symlink to bin2ilk";
   symlink "$LibPath/bin2pd",              'bin2pd' or warn "can't symlink to bin2pd";
   symlink "$LibPath/bin2tpf",             'bin2tpf' or warn "can't symlink to bin2tpf";
   symlink "$LibPath/libgenSearchLib.so",  'libgenSearchLib.so' or warn "can't symlink to libgenSearchLib.so";
   symlink "$LibPath/libplatformLib.so",   'libplatformLib.so' or warn "can't symlink to libplatformLib.so";
   symlink "$LibPath/nseLibTest",          'nseLibTest' or warn "can't symlink to nseLibTest";

   symlink "$RunPath/ruleParser",          'ruleParser' or warn "can't symlink to ruleParser";
   symlink "$RunPath/libruleParserLib.so", 'libruleParserLib.so' or warn "can't symlink to libruleParseLib.so";
   symlink "$RunPath/genRule",             'genRule' or warn "can't symlink to genRule";
   symlink "$RunPath/libgenRuleLib.so",    'libgenRuleLib.so' or warn "can't symlink to libgenRuleLib.so";
   symlink "$RunPath/run_test.pl",         'run_test.pl' or warn "can't symlink to run_test.pl";

   if($nseed >= 0) {
      $seed = $nseed;
   } else {
      $seed=int(rand(100000));
   }

   if($idx_ins eq 'a') {
     $infile="case${section}-${case_num}.in";
     $resultfile="result${section}-${case_num}.log";
   } else {
     $infile="case${section}-${case_num}${idx_ins}.in";
     $resultfile="result${section}-${case_num}${idx_ins}.log";
   }
   print "infile $infile, and resultfile $resultfile\n";

   print TEST_LOG "./run_regression.pl -v $sw_ver -s $section -begin $case_num -end $case_num -n -nseed $seed\n";

   my $starttime=time;
   my $rm_info=$keep_db ? 0:1;
   if(! -e "$RunPath/../../../test_cases/${section}/$infile") {
      print "Case ${section}-${case_num} Missing Database and should be Ignored!\n";
      print $fp_rpt "FAIL!!    NoDatabase  --       --   ---\n";
      goto EndofTestNew;
   } else {
      if($gen_ipf) {
         system"./run_test.pl -case=$RunPath/../../../test_cases/${section}/$infile -result=./$resultfile -seed=$seed -rm_log=$rm_info -rm_bin=$rm_info -rm_in=$rm_info -rm_txt=$rm_info -rm_misc=$rm_info -gen_vid=$gen_vid -gen_ipf=$gen_ipf -gen_tpf=$gen_tpf -gen_pd=$gen_pd";
      } else {
         system"./run_test.pl -case=$RunPath/../../../test_cases/${section}/$infile -result=./$resultfile -seed=$seed -rm_log=$rm_info -rm_bin=$rm_info -rm_in=$rm_info -rm_txt=$rm_info -rm_misc=$rm_info -gen_tpf=$gen_tpf -gen_pd=$gen_pd";
      }
   }

   my $endtime=time;
   my $diff=$endtime-$starttime;
   my $error=0;
   open TLOG, "<$resultfile" or warn "Unable to open $resultfile\n";
   while(<TLOG>) {
      $error++ if /Failed/;
   }
   if($error == 0) {
      print $fp_rpt "Pass      --           ";
   }
   else {
      print $fp_rpt "FAIL!!    --           ";
   }

   printf $fp_rpt "%-13d%-8d\n", $diff, $seed;

   EndofTestNew:
   chdir "../../../../../../..";    # To make sure that after running, the perl work place is back to original path
}

sub entropy_cal {
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
  open TX, "<$_[0]" or die "unable to open $_[0]\n";
  while(<TX>){
    if(/(.*),(.*)/){
      $count1 = $1 =~ tr/1//;
      $count0 = $1 =~ tr/0//;
      $countX = $1 =~ tr/X//;
      #$percent0 = $count0/($count0+$count1+$countX) ;
      #$percent1 = $count1/($count0+$count1+$countX) ;
      #$percentX = $countX/($count0+$count1+$countX) ;
      #$entropy = -($percent0 * logn($percent0,2) + $percent1 * logn($percent1,2)+$percentX * logn($percentX,2));
      #printf("%d, %d, %d, %d, %5.2f, %5.2f, %5.2f, %5.2f \n", $count1, $count0, $countX, $count1+$count0+$countX, $percent0*100, $percent1*100, $percentX*100, $entropy);
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
  printf TEST_LOG "%s, %d, %d, %d, %d, %5.2f, %5.2f, %5.2f, %5.2f \n", $_[0], $tcount1, $tcount0, $tcountX, $tcount1+$tcount0+$tcountX, $percent0*100, $percent1*100, $percentX*100, $entropy;
  close(TX);
}
