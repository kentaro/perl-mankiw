package Mankiw::Manager;
use strict;
use warnings;
use UNIVERSAL::require;
use Parallel::Prefork;

use parent qw(Mankiw::Class);

use Mankiw::Logger;
use Mankiw::Gearman::Dispatcher;

__PACKAGE__->mk_accessors(qw(
    env
    include_paths
    verbose

    gearman
    theschwartz

    max_workers
    max_works_per_child

    timeout_to_wait_terminating
    is_terminated
));

sub init {
    my $self = shift;
    for my $key (keys %{$self->env}) {
        $ENV{$key} ||= $self->env->{$key};
    }
    for my $path (@{$self->include_paths || []}) {
        push @INC, $path;
    }
}

sub worker_type {
    my $self = shift;
    return 'gearman'     if $self->gearman;
    return 'theschwartz' if $self->theschwartz;
    die 'no type found';
}

sub run {
    my ($class, $config) = @_;
    my $self = $class->SUPER::new($config);
       $self->init;

    while ($self->manager->signal_received !~ /(?:TERM|INT)/) {
        $self->manager->start and next;
        $self->set_signal_handlers;

        my $count = $self->manager->num_workers + 1;
        $0 .= " [child process $count]";
        $self->logger->info("$class: $count started (pid: $$)");

        my $i = 0;
        while (($i++ < $self->max_works_per_child) && !$self->is_terminated) {
            if ($self->worker_type eq 'gearman') {
                $self->worker->work(stop_if => sub { $self->is_terminated });
            }
            else {
                die 'not implemented yet';
            }
        }

        $self->logger->info("$class: $count exited (pid: $$)");
        $self->manager->finish;
    }

    $self->finish;
}

sub finish {
    my $self   = shift;
    my $signal = $self->manager->signal_received;

    $self->logger->info("=== Killed by $signal ($$)");

    local $SIG{ALRM} = sub {
        $self->logger->info("Timeout to terminate children");
        $self->kill_all_children;
        exit 1;
    };

    alarm($self->timeout_to_wait_terminating || 10);
    $self->wait_all_children;
    alarm 0;
}

sub set_signal_handlers {
    my $self = shift;
    return if $self->is_parent;

    $SIG{TERM} = sub {
        my $signal = shift;
        $self->is_terminated = 1;
    };

    $SIG{INT} = sub {
        my $signal = shift;
        $self->is_terminated = 1;
        exit 0;
    };
}

sub worker {
    my $self = shift;
    return $self->{_worker} if $self->{_worker};

    my $worker;
    if ($self->worker_type eq 'gearman') {
        my $worker_class = $self->gearman->{worker_class} ||
                           'Mankiw::Gearman::Worker';
        $worker_class->require or die $@;
        $worker = $worker_class->new;
        $worker->prefix($self->gearman->{prefix}) if $self->gearman->{prefix};
        $worker->job_servers(@{$self->gearman->{job_servers}})
            if scalar @{$self->gearman->{job_servers} || []};

        for my $worker_function (@{$self->gearman->{worker_functions}}) {
            $worker->register_function(
                $worker_function,
                Mankiw::Gearman::Dispatcher->can('dispatch'),
            )
        }
    } else {
        die 'not implemented yet';
    }

    $self->{_worker} ||= $worker;
}

sub worker_pids {
    my $self = shift;
    sort keys %{$self->manager->{worker_pids}};
}

sub manager {
    my $self = shift;
    return $self->{_manager} if $self->{_manager};
    $self->{_manager} ||= Parallel::Prefork->new({
        max_workers  => $self->max_workers,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
            QUIT => 'TERM',
            INT  => 'INT',
            USR1 => undef,
        }
    });
}

sub logger {
    my $self = shift;
    return $self->{_logger} if $self->{_logger};
    $self->{_logger} ||= Mankiw::Logger->new(
        outputs => [[
            'Screen',
            min_level => $self->verbose ? 'info' : 'notice',
            newline   => 1,
        ]]
    );
}

sub is_child  { !!shift->manager->{in_child} }
sub is_parent {  !shift->manager->{in_child} }

sub wait_all_children {
    my $self = shift;
    return if $self->is_child;
    $self->manager->wait_all_children;
}

sub kill_all_children {
    my $self = shift;
    return if $self->is_child;
    my $message = sprintf 'Killing children: %s', $self->worker_pids;
    $self->logger->info($message);
    $self->manager->signal_all_children('KILL');
}

!!1;
