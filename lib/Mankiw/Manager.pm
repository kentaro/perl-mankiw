package Mankiw::Manager;
use strict;
use warnings;
use YAML::Syck ();
use Hash::Merge ();
use UNIVERSAL::require;
use Parallel::Prefork;

use parent qw(Mankiw::Class);

use Mankiw::Logger;
use Mankiw::Gearman::Dispatcher;

__PACKAGE__->mk_accessors(qw(
    config_from_file
    config_from_cli

    env
    include_paths
    verbose
    debug

    gearman
    theschwartz

    max_workers
    max_works_per_child
    timeout_to_wait_terminating

    is_terminated
));

sub init {
    my $self = shift;
       $self->merge_config;

    use YAML; warn Dump $self->theschwartz;

    for my $key (keys %{$self->env}) {
        $ENV{$key} = defined $ENV{$key} ? $ENV{$key} : $self->env->{$key};
    }
    for my $path (@{$self->include_paths || []}) {
        unshift @INC, $path;
    }
}

sub merge_config {
    my $self   = shift;
    my $config = Hash::Merge::merge(
        $self->config_from_file,
        $self->config_from_cli,
    );

    for my $key (keys %$config) {
        $self->{$key} = $config->{$key};
    }
}

sub run {
    my ($class, %config) = @_;
    my $self = $class->SUPER::new(\%config);
       $self->init;

    while ($self->to_be_continued) {
        $self->reload if $self->manager->signal_received eq 'HUP';
        $self->manager->start and next;
        $self->set_signal_handlers;

        my $count = $self->manager->num_workers + 1;
        $0 .= " [child process $count]";
        $self->logger->debug("[debug] $class: $count started (pid: $$)");

        my $i = 0;
        while (($i++ < $self->max_works_per_child) && !$self->is_terminated) {
            if ($self->worker_type eq 'gearman') {
                $self->worker->work(stop_if => sub { $self->is_terminated });
            }
            elsif ($self->worker_type eq 'theschwartz') {
                while (!$self->is_terminated && !$self->worker->work_once) {
                    sleep ($self->theschwartz->{delay_to_find_job} || 5);
                }
            }
        }

        $self->logger->debug("[debug] $class: $count exited (pid: $$)");
        $self->manager->finish;
    }

    $self->finish;
}

sub to_be_continued {
    my $self = shift;
    return if $self->debug && $self->manager->signal_received eq 'INT';
    return if $self->manager->signal_received eq 'TERM';
    1;
}

sub reload {
    my $self = shift;
    undef $self->{_worker};

    # for reloading functions
    for my $worker_function (
        @{$self->gearman->{worker_functions}},
        @{$self->theschwartz->{worker_functions}}
    ) {
        (my $path = $worker_function) =~ s{::}{/}g;
        $path .= '.pm';
        delete $INC{$path};
    }

    my $config = YAML::Syck::LoadFile($self->config_file);
    $self->config_from_file = $config;
    $self->merge_config;

    # worker
    $self->max_works_per_child($config->{max_works_per_child});

    # gearman
    $self->gearman = $config->{gearman};

    # manager
    $self->manager->max_workers($config->{max_workers});
    $self->manager->num_workers(0);

    $self->logger->debug('[debug] Reloaded due to HUP');
}

sub finish {
    my $self   = shift;
    my $signal = $self->manager->signal_received;

    $self->logger->debug("[debug] *** Parent process has been killed by $signal ($$) ***");

    local $SIG{ALRM} = sub {
        $self->logger->debug("[debug] Timeout: Waiting for children terminating");
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
    }
    elsif ($self->worker_type eq 'theschwartz') {
        my $worker_class = 'TheSchwartz';
        $worker_class->require or die $@;
        $worker = $worker_class->new(databases => $self->theschwartz->{databases});
        for my $worker_function (@{$self->theschwartz->{worker_functions}}) {
            $worker_function->require or die $@;
            $worker->can_do($worker_function);
        }
    }

    $self->{_worker} ||= $worker;
}

sub worker_type {
    my $self = shift;
    return 'gearman'     if $self->gearman;
    return 'theschwartz' if $self->theschwartz;
    die 'no type found';
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
            min_level => $self->verbose ? 'debug' : 'info',
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
    my $message = sprintf '[debug] Killing children: %s', $self->worker_pids;
    $self->logger->debug($message);
    $self->manager->signal_all_children('KILL');
}

!!1;
