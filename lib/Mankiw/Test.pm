package Mankiw::Test;
use strict;
use warnings;
use FindBin;

use Test::More;
use Test::mysqld;
use Test::TCP qw(wait_port empty_port);

use File::Which qw(which);
use Proc::Guard 0.04 qw(proc_guard);

sub setup_gearman {
    my ($class, %args) = @_;
    my $port       = empty_port();
    my $job_server = proc_guard(scalar(which('gearmand')), '-p', $port);

    eval { wait_port($port) };
    plan(skip_all => $@) if $@;

    my $worker_manager = proc_guard(
        scalar(which('perl')), $args{worker_manager},
        'gearman',
        '-g', "127.0.0.1:$port",
        '-c', $args{config_file},
        '-v',
    );

    ($job_server, $port, $worker_manager);
}

sub setup_theschwartz {
    my ($class, %args)  = @_;
    my $job_server = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
        }
    ) or plan skip_all => $Test::mysqld::errstr;

    open my $fh, "< $args{schema_file}";
    my $schema = do { local $/ = undef; <$fh> };
    close $fh;

    my $dsn = $job_server->dsn(dbname => '');
    my $dbh = DBI->connect($dsn, 'root', '');
       $dbh->do($_) for split /;\s*/, $schema;

    my $worker_manager = proc_guard(
        scalar(which('perl')), $args{worker_manager},
        'theschwartz',
        '-d', $job_server->dsn(dbname => 'test_theschwartz'),
        '-u', 'root',
        '-p', '',
        '-c', $args{config_file},
        '-v',
    );

    ($job_server, $worker_manager);
}

!!1;
