#!/usr/bin/perl
use strict;
# rc = 1        no jil files provided
# rc = 2        not csv file provided
# rc = 3        csv file already exists
# Usage         run script, open it locally in text editor and copy it to a excel

# Check I got at least a parameter which should be the jil file
if ( ! $ARGV[0]  ) {
        print "No jil file provided!.\n";
        print "I need 2 paramters. The first is the jil file and the second the csv file.\n";
        print "Usage: perl jil2csv.v01.pl jilFile.jil csvFile.csv\n";
        exit 1;
}

# Check csv file parameter is given
if ( ! $ARGV[1]  ) {
        print "No csv file provided!.\n";
        print "I need 2 paramters. The first is the jil file and the second the csv file.\n";
        print "Usage: perl jil2csv.v01.pl jilFile.jil csvFile.csv\n";
        exit 2;
}

# Check csv file does not already existes on the file system
if (-e $ARGV[1]) {
        print "The csv file already file exists\n";
        print "Please use a new csv file.\n";
        exit 3;
}

# Array character separator
$" = "Ñ";

# jil file
my $jilFileName = $ARGV[0];

# csv file
my $reportCSV = "$ARGV[1]";

# header keeps as key the parameter name and as value the number it is discovered
my %header;
$header{ insert_job } = 0;
$header{ job_type } = 1;

# index is the number of the value discovered
my $index = 2;

# job keeps the job definition
my @job;

# flat to check first job in jil
my $flagFirstJob = 1;



###########################################################################
# Check if the character separator $Sv is used in the jil file
###########################################################################
#print "######### check_sv\n";
open(my $fh, '<:encoding(UTF-8)', $jilFileName)   or die "Could not open file '$jilFileName' $!";

while ( my $line = <$fh> ) {
        chomp $line;
        if ( $line =~ m/$"/i ) {
                 print qq(### Character $" already on $jilFileName, please chose another character ###\n);
                 close $fh;
                 exit 1;
        }

}

close $fh;




############
# Get header
############
#print "######### get_header\n";
open ($fh, '<:encoding(UTF-8)', $jilFileName ) or die "Could not open $jilFileName $!";

$header{"insert_job"} = 0;
$header{"job_type"} = 1;
my $header_index = 2;

while ( my $line = <$fh>) {
        chomp $line;

        if ( $line =~ m/( *)?(?<PARAMETER>[^:]*):/ ) {                  # (?<PARAMETER>[^:]*) captures the key which is reference later as $+{PARAMETER}
                                #print "$+{PARAMETER}\n";

                                if ( $+{PARAMETER} ne "insert_job" ) {
                        if ( !exists $header{"$+{PARAMETER}"} ) {
                                $header{"$+{PARAMETER}"} = $header_index;
                                $header_index++;
                        }
                }
        }
}

close $fh;


#################
#sort header hash
#################
#print "######### sort_headers\n";

sub hashValueAscendingNum {
   $header{$a} <=> $header{$b};
}
my @sorted_header;
foreach my $key (sort hashValueAscendingNum ( keys ( %header ))) {
   #print "$header{$key}: $key\n";
   push @sorted_header, $key;
}


##############
# print_header
##############
#print "######### print_header\n";

open(my $fh_csv, '>', "$reportCSV") or die "Could not open file '$reportCSV' $!";
$" = 'Ñ';

print $fh_csv "@sorted_header";
print $fh_csv "\n";
close $fh_csv;






open ($fh, '<:encoding(UTF-8)', $jilFileName ) or die "Could not open $jilFileName $!";

open(my $fh_csv, '>>', "$reportCSV") or die "Could not open file '$reportCSV' $!";
my $row = <$fh>;

do {
        # remove while spaces
        $row  =~ s/^\s+|\s+$//g;

        # I do not process empty lines
        unless ( $row =~ /^$/ ) {

                # First time line /* --------------- xxxx appears set the flag to 0
                # From there print job definition.
                if ( $row =~ m</*\s+-----------------\s+.*\s+-----------------\s+.*/> ) {
                        if ( $flagFirstJob == 1 ) {
                                $flagFirstJob = 0;
                        } else {
                                print $fh_csv "@job\n";
                                @job = ();
                        }
                # if line is insert job is a spcial case as it has 2 fields
                } elsif ( $row =~ m/\s*.*insert_job: (.*)\sjob_type: (.*)/ ) {
                        $job[0] = $1;
                        $job[1] = $2;
                } else {
                        #my ($key, $value)  = split /\s:/,$row;
                        $row =~ /\s*(.*?): (.*)/;
                        my $key = $1;
                        my $value = $2;

                        if ( ! exists $header{$key} ) {
                                $header{$key} = $index;
                                $job[$index] = $value;
                                $index++;
                        } else {
                                $job[ $header{ $key } ] = $value;
                        }
                }

                # reach EOF
                if ( eof == 1 ) {
                        print $fh_csv "@job\n";
                }

        }


} while ( $row = <$fh> );
print $fh_csv "@job\n";
