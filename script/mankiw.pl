#!perl
use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;

use Mankiw::Manager;

GetOptions(
    'f|config=s'               => \my $config_file,
    'g|gearman_job_servers=s@' => \my $gearman_job_servers,
    'v|verbose'                => \my $verbose,
    'd|debug'                  => \my $debug,
);

my $config = YAML::Syck::LoadFile($config_file);
   $config->{gearman}{job_servers} = $gearman_job_servers if $gearman_job_servers;
   $config->{verbose}              = $verbose;
   $config->{config_file}          = $config_file;
   $config->{debug}                = $debug;

Mankiw::Manager->run($config);
