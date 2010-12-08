package Mankiw::Logger;
use strict;
use warnings;

use parent qw(Log::Dispatch);

sub log {
    my ($self, %args) = @_;
    my ($sec, $min, $hour, $day, $mon, $year) = localtime();
    $year += 1900;
    $args{message} = "[$year-$mon-$day $hour:$min:$sec] ($args{level}) $args{message}";
    $self->SUPER::log(%args);
}

!!1;
