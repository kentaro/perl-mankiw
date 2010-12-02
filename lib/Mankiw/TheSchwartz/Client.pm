package Mankiw::TheSchwartz::Client;
use strict;
use warnings;
use DBI;

use parent qw(TheSchwartz::Simple);

sub new {
    my ($class, %args) = @_;
    my @dbhs;

    for my $database (@{$args{databases}}) {
        push @dbhs, DBI->connect($database->{dsn}, $database->{user} || '', $database->{pass});
    }

    $class->SUPER::new(\@dbhs);
}

!!1;
