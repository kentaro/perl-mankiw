package Test::Mankiw::Worker::TheSchwartz;
use strict;
use warnings;

use parent qw(Mankiw::TheSchwartz::Worker::Base);

sub work {
    my ($class, $job) = @_;
    open my $fh, '>' . $job->arg->{tmpfile};
    print $fh $job->arg->{result};
    close $fh;
    $job->completed;
}

!!1;
