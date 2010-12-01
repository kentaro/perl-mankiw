package Mankiw::Gearman::Worker;
use strict;
use warnings;

use parent qw(
    Mankiw::Class
    Gearman::Worker
);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;
       $self  = Gearman::Worker->new($self, @_);

    bless $self, $class;
}

!!1;
