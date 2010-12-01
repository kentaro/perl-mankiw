package Mankiw::Client;
use strict;
use warnings;

use parent qw(Mankiw::Class);

__PACKAGE__->mk_accessors(qw(client));

sub insert {
    my ($self, $worker, $args, $options) = @_;
    die 'should be implemented by subclass';
}

!!1;
