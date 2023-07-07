# Catch signals
# List of signals
#       perl -e 'foreach (keys %SIG) { print "$_\n" }'
# https://www.perl.com/article/37/2013/8/18/Catch-and-Handle-Signals-in-Perl/

use strict;
use IO::Select;
use File::Spec;

# capture signal USR1, USR2, TERM, KILL
$SIG{USR1}  = \&signalHandleUSR1;
$SIG{USR2}  = \&signalHandleUSR2;

sub signalHandleUSR1 {
    print "I die!.\n";
    die "Caught a signal $!";
}

sub signalHandleUSR2 {
    print "Signal USR2.\n";
    sleep 10
}



while (1) {
        print "To quit run in another terminal \"kill -USR1 $$\" or \"kill -USR2 $$\" to captura signal USR2 \n"
}
