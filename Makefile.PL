use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {'Mojolicious' => '3.20'},
  test      => {TESTS => 't/*.t'},
  PREREQ_PM => {
  	'Validator::Custom'	=>	0,
  	'Config::Pit'			=>	0,
  	'DateTime'				=>	0,
  	'JSON'					=>	0,
  	'String::Trigram'		=>	0,
  	'Data::Model'			=>	0
  }
);
