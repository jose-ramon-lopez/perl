# log is text.txt
# USR1 signal writes output in lowecase
# USR2 signal writes output in uppercase
# to send a signal      kill -USR1 18541
#
# General Information
#       Catch Sinal
#       All signals perl -e 'foreach (keys %SIG) { print "$_\n" }'
#       https://www.perl.com/article/37/2013/8/18/Catch-and-Handle-Signals-in-Perl/

use strict;
use IO::Select;
use File::Spec;

# Catch Sinal
# All signals perl -e 'foreach (keys %SIG) { print "$_\n" }'
#https://www.perl.com/article/37/2013/8/18/Catch-and-Handle-Signals-in-Perl/
print "My process is $$ \n";

my $case = "uc";

$SIG{USR1}  = \&signal_handlerUSR1;
sub signal_handlerUSR1 {
    $case = "lc";
}

$SIG{USR2}  = \&signal_handlerUSR2;
sub signal_handlerUSR2 {
    $case = "uc";
}


# create log file handler
my $filename = "test.txt";
open my $fh, '<', $filename or die "Can't open '$filename': $!";

# Create the select object with the File handler
my $sel = IO::Select->new( $fh );

# I process log file from the begining sending output to /dev/null
open NULL, '>', File::Spec->devnull() or die "could not open STDERR: $!\n";
print NULL <$fh> ;

# Now I can process new lines in log file
# When the FH has new data
my $line;
while($sel->can_read) {
        $line = <$fh>;

        if ( $line eq "" ) {
                next;
        } else {
                if ( $case eq "uc") {
                        $line = uc $line;
                } elsif ( $case eq "lc") {
                        $line = lc $line;
                }
                print $line;
        }

}



