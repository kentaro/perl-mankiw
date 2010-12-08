use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Mankiw::Test;
use Mankiw::Theschwartz::Client;

my ($job_server, $worker_manager) = Mankiw::Test->setup_theschwartz(
    worker_manager => "$FindBin::Bin/../script/mankiw.pl",
    schema_file    => "$FindBin::Bin/theschwarts.sql",
    config_file    => "$FindBin::Bin/theschwartz.conf.yml",
);
my $dsn = $job_server->dsn(dbname => 'test_theschwartz');
my ($fh, $filename) = tempfile(CLEANUP => 1);
close $fh;

subtest 'theschwartz besic test' => sub {
    my $waiting = 1;

    local $SIG{USR1} = sub {
        $waiting = 0;
        open $fh, "< $filename";
        my $result = do { local $/ = undef; <$fh> };
        close $fh;

        is $result, 1, 'job result of theschwartz worker';

        done_testing;
    };

    local $SIG{ALRM} = sub {
        plan skip_all => 'timeout to wait theschwartz worker';
    };

    my $client = Mankiw::TheSchwartz::Client->new(job_servers => [
        { dsn => $dsn, user => 'root', pass => '' },
    ]);
    $client->insert('Test::Mankiw::Worker::TheSchwartz' => {
        result    => 1,
        tmpfile   => $filename,
        owner_pid => $$,
    });

    alarm 10;
    1 while ($waiting);
    alarm 0;
};

done_testing;
