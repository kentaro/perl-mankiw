package Test::Mankiw::Worker::Gearman;
use strict;
use warnings;

use parent qw(Mankiw::Gearman::Worker::Base);

sub work {
    my ($class, $job) = @_;
    $job->arg->{result};
}

!!1;
