package Mankiw::TheSchwartz::Worker;
use strict;
use warnings;
use Smart::Args;
use TheSchwartz;
use UNIVERSAL::require;

use parent qw(Mankiw::Worker);

sub new {
    args my $class       => 'ClassName',
         my $job_servers => { isa => 'ArrayRef', default => [] };

    my $self = $class->SUPER::new;
       $self->client = TheSchwartz->new(databases => $job_servers);
       $self;
}

sub set_job_servers {
    my ($self, $job_servers) = @_;
    $self->client->hash_databases($job_servers) if $job_servers;
}

sub register_function {
    my ($self, $function_name) = @_;
    $function_name->require or die $@;
    $self->client->can_do($function_name);
}

sub work {
    my ($self, %options) = @_;
    my $stop_condition = $options{stop_if};

    while (!$stop_condition->()) {
        $self->client->work_once($options{job}) and last;
        sleep ($options{delay_to_find_job} || 5);
    }
}

!!1;
