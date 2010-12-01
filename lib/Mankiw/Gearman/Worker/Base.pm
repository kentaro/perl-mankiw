package Mankiw::Gearman::Worker::Base;
use strict;
use warnings;

use parent qw(Mankiw::Worker);

sub work {
    my ($class, $job) = @_;
    die 'should be implemented by subclass';
}

!!1;
