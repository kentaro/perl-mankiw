sub author_tests         {}
sub readme_markdown_from {}
sub auto_set_repository  {}

use inc::Module::Install;

name     'Mankiw';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'Perl';

all_from             'lib/Mankiw.pm';
readme_markdown_from 'lib/Mankiw.pm';

repository 'https://github.com/kentaro/perl-mankiw';
bugtracker 'https://github.com/kentaro/perl-mankiw/issues';
auto_set_repository;

requires 'parent';
requires 'UNIVERSAL::require';
requires 'Class::Data::Inheritable';
requires 'Class::Accessor::Lvalue::Fast';
requires 'DBI';
requires 'Gearman::Client';
requires 'Gearman::Worker';
requires 'TheSchwartz';
requires 'TheSchwartz::Simple';
requires 'Log::Dispatch';
requires 'Parallel::Prefork';
requires 'Smart::Args';
requires 'YAML::Syck';

test_requires 'Test::More' => 0.96; # done_testing, subtest
test_requires 'File::Which';
test_requires 'Test::TCP';
test_requires 'Test::mysqld';
test_requires 'Proc::Guard';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
author_tests('xt');

WriteAll;
