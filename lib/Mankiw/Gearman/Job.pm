package Mankiw::Gearman::Job;
use strict;
use warnings;
use Storable;
use Gearman::Worker;

use base qw(Gearman::Job);

sub arg {
    my $self = shift;
    Storable::thaw($self->SUPER::arg);
}

!!1;
