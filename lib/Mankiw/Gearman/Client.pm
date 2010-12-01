package Mankiw::Gearman::Client;
use strict;
use warnings;
use Gearman::Task;

use parent qw(Mankiw::Client);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;
       $self->client = Gearman::Client->new(@_);
       $self;
}

sub insert {
    my ($self, $worker, $args, $options) = @_;
    $args = ref $args ? Storable::nfreeze($args) : $args;
    $self->client->do_task($worker, $args, $options);
}

!!1;
