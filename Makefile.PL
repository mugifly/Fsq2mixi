use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  test      => {TESTS => 't/*.t'},
  PREREQ_PM => {
 	'Mojolicious' 		=> '3.70',
  	'Validator::Custom'	=>	0,
  	'Config::Pit'			=>	0,
  	'DateTime'				=>	0,
  	'JSON'					=>	0,
  	'String::Trigram'		=>	0,
  	'Data::Model'			=>	0,
  	'Test::Mock::LWP::Conditional'	=>	'0.03',
  }
);
