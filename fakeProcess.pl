#!/usr/bin/perl

use IO::Socket;
my $puerto = @ARGV[0];
my $sock = new IO::Socket::INET (
        LocalPort => $puerto,
        Proto => 'tcp',
        Listen => 1,
        Reuse => 1,
);

die "Could not create socket $!\n" unless $sock;

my $new_sock = $sock->accept();

while (<$new_sock>) { print "$_"; }

close ($sock);
