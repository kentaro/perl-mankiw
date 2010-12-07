package Mankiw::Test;
use strict;
use warnings;
use FindBin;

use Test::More;
use Test::mysqld;
use Test::TCP qw(wait_port empty_port);

use File::Which qw(which);
use Proc::Guard 0.04 qw(proc_guard);

my $worker_manager          = "$FindBin::Bin/../script/mankiw.pl";
my $gearman_config_file     = "$FindBin::Bin/gearman.conf.yml";
my $theschwartz_config_file = "$FindBin::Bin/theschwartz.conf.yml";
my $theschwartz_schema      = "$FindBin::Bin/theschwarts.sql";

sub setup_gearman {
    my $gearmand_port  = empty_port();
    my $gearmand_guard = proc_guard(
        scalar(which('gearmand')),
        '-p', $gearmand_port,
    );

    eval { wait_port($gearmand_port) };
    plan(skip_all => $@) if $@;

    my $gearman_mankiw_guard = proc_guard(
        scalar(which('perl')),
        $worker_manager,
        '-g', "127.0.0.1:$gearmand_port",
        '-f', $gearman_config_file,
    );

    (
        $gearmand_port,
        $gearmand_guard,
        $gearman_mankiw_guard,
    );
}

sub setup_theschwartz {
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
        }
    ) or plan skip_all => $Test::mysqld::errstr;

    open my $fh, "< $theschwartz_schema";
    my $schema = do { local $/ = undef; <$fh> };
    close $fh;

    my $dsn = $mysqld->dsn(dbname => '');
    my $dbh = DBI->connect($dsn, 'root', '');
       $dbh->do($_) for split /;\s*/, $schema;

    my $theschwartz_mankiw_guard = proc_guard(
        scalar(which('perl')), $worker_manager,
        '-i', $mysqld->dsn(dbname => 'test_theschwartz'),
        '-u', 'root',
        '-f',
        $theschwartz_config_file,
    );

    ($mysqld, $theschwartz_mankiw_guard);
}

!!1;