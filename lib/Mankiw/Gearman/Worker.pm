package Mankiw::Gearman::Worker;
use strict;
use warnings;
use Smart::Args;
use Gearman::Worker;

use parent qw(Mankiw::Worker);

sub new {
    args my $class       => 'ClassName',
         my $job_servers => { isa => 'ArrayRef', default => [] };

    my $self = $class->SUPER::new;
       $self->client = Gearman::Worker->new(job_servers => $job_servers);
       $self;
}

sub set_job_servers {
    my ($self, $job_servers) = @_;
    $self->client->job_servers(@$job_servers) if $job_servers;
}

sub register_function {
    my ($self, $function_name, $function) = @_;
    $self->client->register_function($function_name, $function);
}

sub work {
    my ($self, %options) = @_;
    $self->client->work(
        map { $_ => $options{$_} } qw(stop_if on_complete on_fail on_start),
    );
}

!!1;
