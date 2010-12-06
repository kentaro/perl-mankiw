#!perl
use strict;
use warnings;
use YAML::Syck;
use Getopt::Long;
use Project::Libs;

use Mankiw::Manager;

my $config_from_cli = {};

GetOptions(
    'f|config=s'               => \my $config_file,

    # for gearman
    'g|gearman_job_servers=s@' => \$config_from_cli->{gearman_job_servers},

    # for theschwartz
    'u|user=s'                 => \$config_from_cli->{user},
    'p|pass=s'                 => \$config_from_cli->{pass},
    'i|dsn=s'                  => \$config_from_cli->{dsn},

    'v|verbose'                => \$config_from_cli->{verbose},
    'd|debug'                  => \$config_from_cli->{debug},
);

my $config_from_file = YAML::Syck::LoadFile($config_file);
   $config_from_file->{gearman}{job_servers} = $config_from_cli->{gearman_job_servers}
    if $config_from_cli->{gearman_job_servers};
   $config_from_file->{verbose}              = $config_from_cli->{verbose};
   $config_from_file->{config_file}          = $config_from_cli->{$config_file};
   $config_from_file->{debug}                = $config_from_cli->{debug};

if ($config_from_cli->{dsn}) {
    $config_from_cli->{theschwartz}{databases} = [{
        dsn  => $config_from_cli->{dsn},
        user => $config_from_cli->{user} || '',
        pass => $config_from_cli->{pass} || '',
    }];
}

Mankiw::Manager->run(
    config_from_cli  => $config_from_cli,
    config_from_file => $config_from_file,
);
