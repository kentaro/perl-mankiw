use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Mankiw::Test;
use Mankiw::Gearman::Client;

my ($gearmand_port, $gearmand_guard, $gearman_mankiw_guard) = Mankiw::Test->setup_gearman;

subtest 'gearman besic test' => sub {
    my $client = Mankiw::Gearman::Client->new(job_servers => ["127.0.0.1:$gearmand_port"]);
    my $result = $client->insert('Test::Mankiw::Worker::Gearman' => {
        result => 1,
    });

    is $$result, 1, 'return value from gearman';
    done_testing;
};

done_testing;
