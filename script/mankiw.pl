#!perl
use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;
use Project::Libs;

use Mankiw::Manager;

GetOptions(
    'f|config=s'               => \my $config_file,

    # for gearman
    'g|gearman_job_servers=s@' => \my $gearman_job_servers,

    # for theschwartz
    'u|user=s'                 => \my $user,
    'p|pass=s'                 => \my $pass,
    'i|dsn=s'                  => \my $dsn,

    'v|verbose'                => \my $verbose,
    'd|debug'                  => \my $debug,
);

my $config = YAML::Syck::LoadFile($config_file);
   $config->{gearman}{job_servers} = $gearman_job_servers if $gearman_job_servers;
   $config->{verbose}              = $verbose;
   $config->{config_file}          = $config_file;
   $config->{debug}                = $debug;

if ($dsn) {
    $config->{theschwartz}{databases} = [{
        dsn => $dsn, user => $user || '', pass => $pass || '',
    }];
}

Mankiw::Manager->run($config);
