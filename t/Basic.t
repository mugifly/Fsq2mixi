# Basic Test

use Mojo::Base -strict;
use Test::More tests => 4;
use Test::Mojo;

use_ok 'Fsq2mixi';

my $t = Test::Mojo->new('Fsq2mixi');
$t->get_ok('/login')->status_is(200)->content_like(qr/fsq2mixi/i);
