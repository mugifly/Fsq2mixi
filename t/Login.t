# Test for Login

use Mojo::Base -strict;
use Carp 'confess';
$SIG{__WARN__} = sub { confess $_[0] };
use Test::More tests => 4;
use Test::Mojo;
use utf8;

use_ok 'Fsq2mixi';

my $t = Test::Mojo->new('Fsq2mixi');
$t->app->mode("test");# running mode = test
$t->app->hook(before_dispatch => sub {
	my $self = shift;
	$self->app->log->fatal("before-dispatch");
	$self->config->{fsq_client_id}		= 'TEST_FSQCLIENTID';
	$self->config->{fsq_push_secret}	= 'TEST_FSQPUSHSECRET';
	
	# Mock response
	Test::Mock::LWP::Conditional->stub_request(
		# https://ja.foursquare.com/oauth2/access_token
		"https://ja.foursquare.com/oauth2/access_token"	=> HTTP::Response->new(200,"OK",
			[content_type => 'application/json'],
			'{"access_token":"TESTACCESSTOKEN"}'
		),
		# https://api.foursquare.com/v2/users/self
		"https://api.foursquare.com/v2/users/self"	=> HTTP::Response->new(200,"OK",
			[content_type => 'application/json'],
			JSON->new->encode({
				meta => {
					code => 200
				},
				response => {
					user => {
						id	=>	9999999999999,
						firstName => "test",
						relationship => "self",
						#...
					}
				}
			})
		)
	);
});

$t->get_ok('/oauth_callback_fsq?code=testauthcode')->status_is(302)->header_like(Location => qr|http://localhost:\d+/\?logined|);

