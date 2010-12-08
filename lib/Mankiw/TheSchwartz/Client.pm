package Mankiw::TheSchwartz::Client;
use strict;
use warnings;

use DBI;
use Smart::Args;

use parent qw(TheSchwartz::Simple);

sub new {
    args my $class       => 'ClassName',
         my $job_servers => 'ArrayRef';

    my @dbhs;
    for my $job_server (@$job_servers) {
        push @dbhs, DBI->connect(
            $job_server->{dsn},
            $job_server->{user},
            $job_server->{pass},
        );
    }

    $class->SUPER::new(\@dbhs);
}

sub job_servers {
    my $self = shift;
    $self->{databases} = shift if $_[0];
    $self->{databases};
}

!!1;
