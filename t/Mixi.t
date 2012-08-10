use Mojo::Base -strict;

# Test for Mixi Module (Methods for Tests)
use Test::More tests => 3;
use utf8;

use_ok("Mixi");

my $mixi = Mixi->new("consumer_key"=> "TEST", "isTest" => 1);
can_ok($mixi, 'getUser_MixiName');

is($mixi->getUser_MixiName(),'アヤコ');

