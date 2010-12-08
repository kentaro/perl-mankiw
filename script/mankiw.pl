#!perl
use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;
use Project::Libs;
use List::MoreUtils qw(each_array);

use Mankiw::Manager;

my $worker_type = shift;

die "usage: $0 (gearman|theschwartz) ..."
    if ($worker_type || '') !~ /(?:gearman|theschwartz)/;

my $config_from_cli = {worker_type => $worker_type};
my $job_servers     = {
    gearman     => {},
    theschwartz => {},
};

GetOptions(
    'c|config=s' => \my $config_file,
    'v|verbose'  => \$config_from_cli->{verbose},

    # for gearman
    'g|job_server=s@' => \$job_servers->{gearman}{job_servers},

    # for theschwartz
    'd|dsn=s@'  => \$job_servers->{theschwartz}{job_servers}{dsn},
    'u|user=s@' => \$job_servers->{theschwartz}{job_servers}{user},
    'p|pass=s@' => \$job_servers->{theschwartz}{job_servers}{pass},
);

my $config_from_file = YAML::Syck::LoadFile($config_file);

if ($worker_type eq 'gearman') {
    delete $config_from_cli->{theschwartz};
    $config_from_cli->{job_servers} = $job_servers->{gearman}{job_servers};
}
else {
    delete $config_from_cli->{gearman};
    my @job_servers;
    my $walker = each_array
        @{$job_servers->{theschwartz}{job_servers}{dsn}  || []},
        @{$job_servers->{theschwartz}{job_servers}{user} || []},
        @{$job_servers->{theschwartz}{job_servers}{pass} || []};

    while (my ($dsn, $user, $pass) = $walker->()) {
        push @job_servers, {
            dsn  => defined $dsn  ? $dsn  : '',
            user => defined $user ? $user : '',
            pass => defined $pass ? $pass : '',
        }
    }
    $config_from_cli->{job_servers} = \@job_servers;
}

Mankiw::Manager->run(
    config_precedent => $config_from_cli,
    config           => $config_from_file,
    config_file      => $config_file || '',
);
