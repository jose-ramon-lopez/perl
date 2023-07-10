#!/usr/bin/perl

use warnings;
no warnings 'uninitialized';

use v5.14;
use utf8;

binmode STDOUT, ':utf8';
binmode STDIN, ':utf8';

$" = "Ñ";
my $input_file_name = shift @ARGV or die "Usage: FILENAME\n";

open(my $fh, '<:encoding(UTF-8)', $input_file_name)  or die "Could not open file '$input_file_name' $!";

my %header;
my $index;
my @job_definition;

while (my $row = <$fh>) {
        #print $row;
        chomp $row;
        $row =~ m/([^:]+):\s+(.*)/;
        my $key = $1;
        my $value = $2;

        if ( $key eq "job_name" ) {
                print "JOB DEFINITION; @job_definition\n" if ( @job_definition);
                @job_definition = ();
        }

        if ( !exists $header{ $key  } ) {
                $header{ $key  } = ++$index;
                $job_definition[ $index ] = $value;
        } else {
                $job_definition[ $header{ $key}  ] = $value;
        }


}

print "JOB DEFINITION; @job_definition\n";

my @header = sort sort_headers keys %header;
print "@header\n";



sub sort_headers {
        $header{$a} <=> $header{$b} # by descending numeric score
        or
        $a cmp $b # code point order by name
} @header
