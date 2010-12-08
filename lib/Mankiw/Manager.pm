package Mankiw::Manager;
use strict;
use warnings;
use YAML::Syck ();
use UNIVERSAL::require;
use Parallel::Prefork;

use parent qw(Mankiw::Class);

use Mankiw::Logger;
use Mankiw::Gearman::Dispatcher;

__PACKAGE__->mk_accessors(qw(
    config_precedent
    config
    config_file

    env
    include_paths
    verbose

    worker_type

    job_servers
    worker_class
    worker_functions
    max_workers
    max_works_per_child
    delay_to_find_job

    timeout_to_wait_terminating
    is_terminated

    info
));

sub init {
    my $self = shift;
       $self->merge_config;

    for my $key (keys %{$self->env}) {
        $ENV{$key} = defined $ENV{$key} ? $ENV{$key} : $self->env->{$key};
    }
    for my $path (@{$self->include_paths || []}) {
        unshift @INC, $path;
    }

    $self->info ||= {};
}

sub is_debug_mode { !!$ENV{MANKIW_DEBUG} }

sub merge_config {
    my $self   = shift;
    my $config = {
       %{$self->config},
       %{$self->config_precedent},
    };

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
        $self->run_worker;
        $self->logger->debug("$class: exited (pid: $$)");
        $self->manager->finish;
    }

    $self->finish;
}

sub identifier :lvalue {
    my $self = shift;
    $self->info->{processes}{$$}{identification};
}

sub run_worker {
    my $self  = shift;
    my $class = ref $self;

    return if $self->is_parent;

    $self->set_signal_handlers;

    $0 .= " [child process]";
    $self->logger->debug("$class: started (pid: $$)");

    my $i = 0;
    while (($i++ < $self->max_works_per_child) && !$self->is_terminated) {
        $self->worker->work(
            stop_if           => sub { $self->is_terminated },
            delay_to_find_job => $self->delay_to_find_job || 5,
        );
    }
}

sub to_be_continued {
    my $self = shift;
    return if $self->is_debug_mode && $self->manager->signal_received eq 'INT';
    return if $self->manager->signal_received eq 'TERM';
    1;
}

sub reload {
    my $self   = shift;
    my $config = YAML::Syck::LoadFile($self->config_file);
    $self->config = $config;
    $self->merge_config;

    # for reloading worker
    undef $self->{_worker};

    # for reloading worker functions
    for my $worker_function (@{$self->worker_functions}) {
        (my $path = $worker_function) =~ s{::}{/}g;
        $path .= '.pm';
        delete $INC{$path};
    }

    # reconfigure manager
    $self->manager->max_workers($self->max_workers);

    $self->logger->debug('Reloaded due to HUP');
}

sub finish {
    my $self   = shift;
    my $signal = $self->manager->signal_received;

    $self->logger->debug("*** Parent process has been killed by $signal ($$) ***");

    local $SIG{ALRM} = sub {
        $self->logger->debug("Timeout: Waiting for children terminating");
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

    my $worker_class = $self->worker_class || (
           $self->worker_type eq 'theschwartz' ?
               'Mankiw::TheSchwartz::Worker' : 'Mankiw::Gearman::Worker'
       );
       $worker_class->require or die $@;
    my $worker = $worker_class->new;
       $worker->set_job_servers($self->job_servers)
           if scalar @{$self->job_servers || []};

    for my $worker_function (@{$self->worker_functions}) {
        $worker->register_function(
            $worker_function,
            Mankiw::Gearman::Dispatcher->can('dispatch'),
        )
    }

    $worker;
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
    my $message = sprintf 'Killing children: %s', $self->worker_pids;
    $self->logger->debug($message);
    $self->manager->signal_all_children('KILL');
}

!!1;
