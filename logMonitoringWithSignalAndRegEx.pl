# Log monitoring
#
# signal: USR1 loads config file
#       kill -USR1 $(ps -ef | grep "[p]erl logMonitoringInit.pl" | cut -d " " -f 7)
# signal: USR2 prints the config file
#       kill -USR2 $(ps -ef | grep "[p]erl logMonitoringInit.pl" | cut -d " " -f 7)
# signal documentation
#       All signals:    perl -e 'foreach (keys %SIG) { print "$_\n" }'
#       Catch signals:  https://www.perl.com/article/37/2013/8/18/Catch-and-Handle-Signals-in-Perl
#
# variable: $flagStart
#       0       process log file from the beginning
#       1       process log file since script is started
#
# Character classes:
#       https://en.wikipedia.org/wiki/Regular_expression#Character_classes

use strict;
use IO::Select;
use File::Spec;


## Variables globales
my %configFile;
my $seccion = "";
my $logFile = "log.log";
my $flagStart = 0;
my $configFile = "initfile.ini";


## Defino las funciones que campuran las signals
$SIG{USR1}  = \&signal_handlerUSR1;
$SIG{USR2}  = \&signal_handlerUSR2;


#print "My process is $$ \n";


## Subrutinas
# USR1 carga el fichero de configuracion
sub signal_handlerUSR1 {
        print "Cargando fichero configuracion...\n";
        my $logFile = 'initfile.ini';

        open(my $fh, '<:encoding(UTF-8)', $configFile)
                or die "Could not open file '$configFile' $!";

        while ( my $row = <$fh> ) {
                chomp $row;
                # print "$row\n";
                # remove comments and empty lines
                if ( $row =~ /^[[:space:]]*#/ ) {
                        next;
                } elsif ( $row =~ /^[[:space:]]*$/ ) {
                        next;
                } elsif ( $row =~ /\[(.+)\]/) {
                        $seccion = $1;
                        # print "HashKey: $seccion\n";
                ## I define here the characters allowed in job name
                #[:space:]]*([[:alnum:]_]
                #
                } elsif ( $row =~ /^[[:space:]]*([[:alnum:]_]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*/ ) {
                        my $key = $1;
                        my $value = $2;
                        # print "Key: $key, Value: $value\n";
                        $configFile{ $seccion }{ $key } = $value;
                        # print "-- $seccion -- $key -- $configFile{ $seccion }{ $key } --\n";
                } else {
                        # print "$row\n";
                }

        }
        print "Fichero de configuracion cargado.\n";
}


# USR2 muestra el config file
sub signal_handlerUSR2 {
        print "**************************************\n\n";
        for my $key ( keys %configFile) {
                print "Seccion: $key\n";

                for my $secondKey ( keys %{ $configFile{ $key  }} ) {
                        print "-- $secondKey -- $configFile{$key}{$secondKey}\n";
                }

        }
}



############
### MAIN ###
############

## Cargo y muestro el archivo de configuración
signal_handlerUSR1();
signal_handlerUSR2();

print "\n\n";


# create log file handler para el log
open my $fh, '<', $logFile or die "Can't open '$logFile': $!";


# Create the select object with the File handler
my $sel = IO::Select->new( $fh );


# I process log file from the begining sending output to /dev/null only if $flagStart == 1
if ( $flagStart == 1 ) {
        open NULL, '>', File::Spec->devnull() or die "could not open STDERR: $!\n";
        print NULL <$fh> ;
}


# Now I can process new lines in log file
# When the FH has new data

my $row;
while ( $sel->can_read ) {
        $row = <$fh>;

        # If no new line ready to be processed an empty line is read while waiting for new log lines
        # discard empty lines
        if ( $row eq "" ) {
                next;
        } else {

                chomp( $row );
                #print "--$row##\n";


                # get data for job failure lines
                if ( $row =~ m/JOB: (.*) RC=(.*)/ ) {
                        my $job = $1;
                        my $rc = $2;

                        #print "ROW: $row\n";
                        #print "JOB: $job\n";

                        my $maxMatchLength = 0;
                        my $match = "";
                        my $action = "";

                        for my $key ( keys %configFile) {

                                #print "KEY: $key\n";

                                for my $secondKey ( keys %{ $configFile{ $key  }} ) {

                                        #print "SECOND KEY: #$secondKey#\n";

                                        if ( $job =~ m/$secondKey/ ) {
                                                #print "MATCH: $secondKey - $row\n";
                                                # $& la parte que hizo match
                                                # $` la parte anterior al match
                                                # $' la parte posterior al match
                                                my $matchLength = length($&);

                                                if ($matchLength > $maxMatchLength )  {
                                                        $match = $&;
                                                        $action = $configFile{$key}{$secondKey};
                                                        $maxMatchLength = $matchLength;
                                                }
                                                #print "MATCH: $& LENGTH: $matchLength ACTION: $configFile{$key}{$secondKey}\n";

                                        }

                                        #if ($maxMatchLength != 0 ) {
                                        #               print "MATCH: $match LENGTH: $maxMatchLength ACTION: $action \n";
                                        #}


                                }

                        }

                        if ($maxMatchLength != 0 ) {
                                print "JOBNAME: $job RC: $rc MATCH: $match LENGTH: $maxMatchLength ACTION: $action \n\n";
                        }
                } else {
                        next;
                        # otras alertas
                }
        }
}

