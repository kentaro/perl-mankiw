#!perl
use strict;
use warnings;
use YAML;
use Getopt::Long;

use Mankiw::Manager;

GetOptions(
    'f|config=s'               => \my $config_file,
    'g|gearman_job_servers=s@' => \my $gearman_job_servers,
    'v|verbose'                => \my $verbose,
);

my $config = YAML::LoadFile($config_file);
   $config->{gearman}{job_servers} = $gearman_job_servers if $gearman_job_servers;
   $config->{verbose} = $verbose;

Mankiw::Manager->run($config);
