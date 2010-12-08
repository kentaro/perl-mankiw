use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Mankiw::Test;
use Mankiw::Gearman::Client;

my ($job_server, $port, $worker_manager) = Mankiw::Test->setup_gearman(
    worker_manager => "$FindBin::Bin/../script/mankiw.pl",
    config_file    => "$FindBin::Bin/gearman.conf.yml",
);

subtest 'gearman besic test' => sub {
    my $client = Mankiw::Gearman::Client->new(job_servers => ["127.0.0.1:$port"]);
    my $result = $client->insert('Test::Mankiw::Worker::Gearman' => {
        result => 1,
    });

    is $$result, 1, 'return value from gearman';
    done_testing;
};

done_testing;
