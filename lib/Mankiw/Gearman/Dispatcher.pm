package Mankiw::Gearman::Dispatcher;
use strict;
use warnings;
use UNIVERSAL::require;
use Mankiw::Gearman::Job;

sub dispatch {
    my $job = shift;
    my $worker_class = $job->{func};
       $worker_class->require or die $@;
       $worker_class->work(bless $job, 'Mankiw::Gearman::Job');
}

!!1;
