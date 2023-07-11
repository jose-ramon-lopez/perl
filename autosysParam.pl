#!/usr/bin/perl
#usage: perl extract_jobname_&_another_parameter_from_autorep.pl autorep.jil parameter
#       autorep.jil = file created by 'autorep -J xxxx' -q command
#       parameter       = an autosys parameter as machine, owner....
use strict;
if ( @ARGV != 2 ) {
        print "###########################################\n";
        print "####### Wrong number of arguments. ########\n";
        print "### You must specify just two arguments ###\n";
        print "###########################################\n";
        print "\n";
        exit 1;
}
my $filename = $ARGV[0];
my $parameter = $ARGV[1];

open (my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";

my $jobname;

while ( my $row = <$fh>) {
        chomp $row;

                $jobname = $1 if ($row =~ m/insert_job: (.*?) .*/);
                print "$jobname $parameter: $1\n" if ( $row =~ m/$parameter: (.*)/ )
}