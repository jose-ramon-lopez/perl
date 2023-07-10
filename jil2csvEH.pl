#!/usr/bin/perl
### This script converts a jil file into a csv file
### usage: "perl jil2csv.pl" from MobaXterm or any PC with perl v5.14 installed
### Input file hardcoded to jobs.jil
### Output file hardcoded to jobs.csv
### If output file exists it is overwritten!!!!
###
### Return codes
### RC = 1      separated value on input file
###
### Variables
### $SV is the CSV carachter separator hardcoded to letter "Ñ"
### $input_filename is the jil file
### $output_filename output csv file

use warnings;
use v5.14;
no warnings 'uninitialized';
use utf8;

binmode STDOUT, ':utf8';
binmode STDIN, ':utf8';

# $SV is the CSV carachter separator
my $SV = "Ñ";

# input and output files
my $input_filename = 'p11.jil.txt';
my $output_filename = 'p11.jil.txt.csv';


##################
### subrutines ###
##################

### Print job definition into CSV file

sub print_array {
        open ( my $fh_out, '>>', $output_filename )  or die "Could not open $output_filename $!";
        my @array = @_;

        foreach my $element (@array) {
        chomp $element;

                if ( !defined $element ) {
                        print $fh_out "$SV";
                } else {
                        print $fh_out "${element}$SV";
                }
        }

        print $fh_out "\n";
        close $fh_out;
}

### Check Separator file is not on the jil file

sub check_sv {
        open ( my $fh_in_header, '<', $input_filename ) or die "Could not open $input_filename $!";
        while ( my $line = <$fh_in_header> ) {
                chomp $line;
                if ( $line =~ m/$SV/ ) {
                        print "### Character $SV already on $input_filename, please chose another character ###\n";
                        close $fh_in_header;
                        exit 1;
                }
        }
        close $fh_in_header;
}

####################
### Main program ###
####################

# check separator csv character is not on jil file
check_sv;

### Get header
### Read input file to get in hash the header

open (my $fh_in, '<', $input_filename ) or die "Could not open $input_filename $!";

my %header;
$header{"insert_job"} = 0;
$header{"job_type"} = 1;

my $header_index = 2;

while ( my $line = <$fh_in>) {
        chomp $line;

        if ( $line =~ m/insert_job/ ) {
                ;
        } elsif ( $line =~ m/( *)?(?<PARAMETER>.*):( *)?(?<TEXT>.*)/ ) {

                # if parameter is already in hash it must not be included again
                next if ( exists $header{"$+{PARAMETER}"} );

                # Case two colons (start_time, run_window....)
                if ( $+{PARAMETER} =~ /:/ ) {
                        $line =~ m/( *)?(?<PARAMETER>.*): "(?<TEXT>.*)"/;
                        next if ( exists $header{"$+{PARAMETER}"} );
                        $header{"$+{PARAMETER}"} = $header_index;
                        $header_index++;
                } else {
                # Case only 1 colon (command, box_name...)
                        next if ( exists $header{"$+{PARAMETER}"} );
                        $header{"$+{PARAMETER}"} = $header_index;
                        $header_index++;
                }
        }
}

close $fh_in;

### write headers on csv file
open ( my $fh_out_header, '>>', $output_filename )  or die "Could not open $output_filename $!";

foreach my $parameter (sort { $header{$a} <=> $header{$b} } keys %header) {
        print $fh_out_header "$parameter$SV";
}

print $fh_out_header "\n";
close $fh_out_header;

### Write job def on csv file
### Read for second time input file

open ( $fh_in, '<:encoding(UTF-8)', $input_filename ) or die "Could not open $input_filename $!";

my @job_def = "";

### 3 cases
### a insert job
### lines with 2 : not being insert_job
### lines with 1 :
while ( my $line = <$fh_in> ) {
        chomp $line;
        if ( $line =~ m/insert_job: (?<JOBNAME>[a-zA-Z0-9._-]*) *job_type: (?<JOBTYPE>[a-zA-Z0-9._-]*)/ ) {
                        print_array @job_def if ( @job_def != "1" );
                        @job_def = "";
                        $job_def[0] = $+{JOBNAME};
                        $job_def[1] = $+{JOBTYPE};
        } elsif ( $line =~ m/( *)?(?<PARAMETER>.*):( *)?(?<TEXT>.*)/ ) {
                if ( $+{PARAMETER} =~ /:/ ) {
                        $line =~ m/( *)?(?<PARAMETER>.*): "(?<TEXT>.*)"/;
                        $job_def[$header{$+{PARAMETER}}] = $+{TEXT};
                } else {
                        $job_def[$header{$+{PARAMETER}}] = $+{TEXT};
                }
        }
}
print_array @job_def if ( @job_def != "1" );
close $fh_in;
