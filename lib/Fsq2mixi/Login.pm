package Fsq2mixi::Login;
use utf8;
use Mojo::Base 'Mojolicious::Controller';


sub foursquare {
	my $self = shift;
	
		$self->render(
		message => 'Foursquareへのログイン'
		
	);
}

sub foursquare_redirect_authpage {
	my $self = shift;
	$self->redirect_to("https://foursquare.com/oauth2/authenticate?client_id=".$self->config->{fsq_client_id}."&response_type=code&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq");
}

sub foursquare_redirect_callback {
	my $self = shift;
	my $ua = $self->ua->new;
	my $token = $ua->get('https://ja.foursquare.com/oauth2/access_token'.
		'?client_id='.$self->config->{fsq_client_id}.
		'&client_secret='.$self->config->{fsq_client_secret}.
		'&grant_type=authorization_code'.
		'&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq'.
		'&code='.$self->param("code")
	)
	->res->json('/access_token');
	$self->render(message => "OK");
	
}

1;