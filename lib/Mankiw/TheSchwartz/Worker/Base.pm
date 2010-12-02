package Mankiw::TheSchwartz::Worker::Base;
use strict;
use warnings;

use parent qw(
    TheSchwartz::Worker
    Mankiw::Class
);

sub work {
    my ($class, $job) = @_;
    #die 'should be implemented by subclass';
}

!!1;
