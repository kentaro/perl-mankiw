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

__PACKAGE__->mk_accessors(qw(
    client
));

sub job_servers {
    my ($self, @job_servers) = @_;
    die 'should be implemented by subclass';
}

sub register_function {
    my ($self, $function_name, $function) = @_;
    die 'should be implemented by subclass';
}

sub work {
    my ($class, %options) = @_;
    die 'should be implemented by subclass';
}

!!1;
