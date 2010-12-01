use strict;
use warnings;
use FindBin;

use Test::TCP;
use Test::More;

use Project::Libs;
use File::Which qw(which);
use Proc::Guard 0.04 qw(proc_guard);

use Mankiw::Gearman::Client;

my $config_file    = "$FindBin::Bin/test.conf";
my $worker_manager = "$FindBin::Bin/../script/mankiw.pl";

test_tcp(
    client => sub {
        my $port = shift;
        my $worker_guard = proc_guard(
            scalar(which('perl')),
            $worker_manager,
            '-g', "127.0.0.1:$port",
            '-f', $config_file,
        );
        my $client = Mankiw::Gearman::Client->new(job_servers => ["127.0.0.1:$port"]);
        my $result = $client->insert('Test::Mankiw::Worker::Gearman' => {
            result => 1,
        }, {
            on_complete => sub { ok 1 }
        });

        is $$result, 1;
    },
    server => sub {
        my $port = shift;
        exec scalar(which('gearmand')), '-p', $port;
    }
);

done_testing;
