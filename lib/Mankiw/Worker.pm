package Mankiw::Worker;
use strict;
use warnings;

use parent qw(Mankiw::Class);

use Mankiw::Logger;
__PACKAGE__->mk_classdata(
    logger => Mankiw::Logger->new(
        outputs => [[
            'Screen',
            min_level => 'info',
            newline   => 1,
        ]],
    )
);

sub work {
    my ($class, $job) = @_;
    die 'should be implemented by subclass';
}

!!1;
