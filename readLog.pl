# Leo log desde la última línea
use IO::Select;

my $filename = "test.txt";

open my $fh, '<', $filename or die "Can't open '$filename': $!";
$sel = IO::Select->new( $fh );

while(@ready = $sel->can_read) {
        print <$fh>;

}


