use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Mankiw;
use Mankiw::Theschwartz::Client;

my ($mysqld, $theschwartz_mankiw_guard) = Test::Mankiw->setup_theschwartz;
my $dsn = $mysqld->dsn(dbname => 'test');
my $tmpfile = tempfile(CLEANUP => 1);

subtest 'theschwartz besic test' => sub {
    my $client = Mankiw::TheSchwartz::Client->new(databases => [{ dsn => $dsn, user => 'root', pass => '' }]);
        $client->insert('Test::Mankiw::Worker::TheSchwartz' => {
            result  => 1,
            tmpfile => $tmpfile,
        });

    sleep 5;

    open my $fh, '<' . $tmpfile;
    my $result = do { local $/ = undef; <$fh> };
    is $result, 1, 'return value from gearman';
    close $fh;

    done_testing;
};

done_testing;
