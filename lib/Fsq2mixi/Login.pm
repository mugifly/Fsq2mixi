package Fsq2mixi::Login;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;

sub mixi_redirect_authpage {
	my $self = shift;
	# Temporary-flash for consistency check
	$self->flash(auth_flg => 'mixiauth-'.$self->config->{mixi_consumer_key});
	
	# Redirect client to mixi auth-page
	my $mixi = Mixi->new('consumer_key'=> $self->config->{mixi_consumer_key}, 'consumer_secret' => $self->config->{mixi_consumer_secret});
	$self->redirect_to($mixi->getRedirectURL());
}

sub mixi_callback {
	my $self = shift;
	# Checking consistency
	if(($self->flash("auth_flg") ne 'mixiauth-'.$self->config->{mixi_consumer_key}) || $self->param('code') eq ""){
		$self->redirect_to('/');
	}
	
	# Get access-token from mixi-server
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret});
	my ($mixi_token, $mixi_rtoken) = $mixi->getTokens($self->param('code'));
	
	# Load session
	my $fsq_token = $self->session('fsq_token');
	
	# Update user-data on DB
	my ($d, ) = $self->db->get('user' => {
		where => [
			fsq_token => $fsq_token
		],
	});
	$d->mixi_token($mixi_token);
	$d->mixi_rtoken($mixi_rtoken);
	$d->update;
	
	# Redirect client
	$self->redirect_to('/');
}

sub foursquare_redirect_authpage {
	my $self = shift;
	# Temporary-flash for consistency check
	$self->flash(auth_flg => 'fsqauth-'.$self->config->{fsq_client_id});
	
	# Redirect client to mixi auth-page
	$self->redirect_to("https://foursquare.com/oauth2/authenticate?client_id=".$self->config->{fsq_client_id}."&response_type=code&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq");
}

sub foursquare_callback {
	my $self = shift;
	# Checking consistency
	if($self->flash("auth_flg") ne 'fsqauth-'.$self->config->{fsq_client_id} || $self->param("code") eq ""){
		$self->redirect_to('/');
	}
	
	# Get access-token from 4sq-server
	my $ua = Mojo::UserAgent->new;
	my $token = $ua->get('https://ja.foursquare.com/oauth2/access_token'.
		'?client_id='.$self->config->{fsq_client_id}.
		'&client_secret='.$self->config->{fsq_client_secret}.
		'&grant_type=authorization_code'.
		'&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq'.
		'&code='.$self->param("code")
	)
	->res->json('/access_token');
	
	# Get user-data from 4sq-server
	my $js = $ua->get('https://api.foursquare.com/v2/users/self?oauth_token='.$token);
	my $fsq_id = $js->res->json('/response/user/id');
	
	# Insert user-data to DB
	$self->db->set('user'=> {
		fsq_token => $token,
		fsq_id => $fsq_id,
		mixi_is_active => 1,
		mixi_is_makemyspot => 1,
		mixi_mode => 'voice'
	});
	
	# Save session
	$self->session(fsq_token => $token);
	
	# Redirect client
	$self->redirect_to('/');
}

1;
