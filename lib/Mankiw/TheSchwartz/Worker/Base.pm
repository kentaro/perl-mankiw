package Mankiw::TheSchwartz::Worker::Base;
use strict;
use warnings;

use parent qw(Theschwartz::Worker);

sub work {
    my ($class, $job) = @_;
    1;
    #die 'should be implemented by subclass';
}

!!1;
