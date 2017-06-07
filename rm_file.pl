#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use File::Basename;


for (my $j=1; $j<50; $j++) {
   #if(-e "./$j/a/SquidSim") {
   #   chdir "./$j/a/SquidSim";
   #   system"mv rtl_out.0.bin.vend0.request.ipf ilk_in.ipf";
   #   system"mv rtl_out.0.bin.vend0.response.ipf ilk_out.ipf";
   #   system"rm nseTest.log rtl_out.0.bin rtl_out.1.bin";
   #   chdir "../../..";
   #}
   if(-e "./$j/b/SquidSim") {
      chdir "./$j/b/SquidSim";
      system"mv rtl_out.0.bin.vend0.request.ipf ilk_in.ipf";
      system"mv rtl_out.0.bin.vend0.response.ipf ilk_out.ipf";
      system"rm nseTest.log rtl_out.0.bin rtl_out.1.bin";
      chdir "../../..";
   }
   if(-e "./$j/c/SquidSim") {
      chdir "./$j/c/SquidSim";
      system"mv rtl_out.0.bin.vend0.request.ipf ilk_in.ipf";
      system"mv rtl_out.0.bin.vend0.response.ipf ilk_out.ipf";
      system"rm nseTest.log rtl_out.0.bin rtl_out.1.bin";
      chdir "../../..";
   }
   if(-e "./$j/d/SquidSim") {
      chdir "./$j/d/SquidSim";
      system"mv rtl_out.0.bin.vend0.request.ipf ilk_in.ipf";
      system"mv rtl_out.0.bin.vend0.response.ipf ilk_out.ipf";
      system"rm nseTest.log rtl_out.0.bin rtl_out.1.bin";
      chdir "../../..";
   }
}
