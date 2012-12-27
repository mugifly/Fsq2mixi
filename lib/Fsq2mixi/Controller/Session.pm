package Fsq2mixi::Controller::Session;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;
use LWP::UserAgent;
use Mojo::JSON;

sub oauth_mixi_redirect {
	my $self = shift;
	# Temporary-flash for consistency check
	$self->flash(auth_flg => 'mixiauth-'.$self->config->{mixi_consumer_key});
	
	# Redirect client to mixi auth-page
	my $mixi = Mixi->new('consumer_key'=> $self->config->{mixi_consumer_key}, 'consumer_secret' => $self->config->{mixi_consumer_secret});
	$self->redirect_to($mixi->getRedirectURL());
}

sub oauth_mixi_callback {
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
	
	if($mixi_token eq ""){
		$self->redirect_to('/?callback_valid');
		return;
	}
	
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
	$self->redirect_to('/?'.$mixi_token);
}

sub oauth_foursquare_redirect {
	my $self = shift;
	# Temporary-flash for consistency check
	$self->flash(auth_flg => 'fsqauth-'.$self->config->{fsq_client_id});
	
	# Redirect client to mixi auth-page
	$self->redirect_to("https://foursquare.com/oauth2/authenticate?client_id=".
		$self->config->{fsq_client_id}."&response_type=code&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/session/oauth_foursquare_callback");
}

sub oauth_foursquare_callback {
	my $self = shift;
	# Checking consistency
	if($self->app->mode ne "test" && $self->flash("auth_flg") ne 'fsqauth-'.$self->config->{fsq_client_id} || $self->param("code") eq ""){
		$self->redirect_to('/?callback_valid');
		return 1;
	}
	
	# Get access-token from 4sq-server
	my $ua = LWP::UserAgent->new;
	my $js = Mojo::JSON->decode($ua->post('https://ja.foursquare.com/oauth2/access_token',
		{
			client_id		=>	$self->config->{fsq_client_id},
			client_secret	=>	$self->config->{fsq_client_secret},
			grant_type		=>	'authorization_code',
			redirect_uri	=>	'https://s1.mpnets.net/services/fsq2mixi/session/oauth_foursquare_callback',
			code			=>	$self->param("code")
		}
	)->content);
	my $token = $js->{access_token};
	
	if(!defined($token) || $token eq ""){
		# if Token is valid...
		$self->app->log->fatal("re");
		$self->redirect_to('/?access_token_valid');
		return 1;
	}
	
	# Get user-data from 4sq-server
	$js = Mojo::JSON->decode($ua->get('https://api.foursquare.com/v2/users/self', 'Authorization' => 'OAuth '.$token)->content);
	my $fsq_id = $js->{response}->{user}->{id};
	
	# Insert and Update user-data to DB
	my $row = $self->db->find_or_create(
		user => {
           fsq_id => $fsq_id,
		} => {
			fsq_token				=> $token,
			fsq_id					=> $fsq_id,
			mixi_is_active		=> 1,
			mixi_is_makemyspot	=> 1,
			mixi_mode				=> 'voice'
		}
	);
	$row->fsq_token($token);
	$row->fsq_id($fsq_id);
	$row->update;
	
	# Save session
	$self->session(expiration=> $self->config->{session_expires});
	$self->session(fsq_token => $token);
	
	# Redirect client
	$self->redirect_to('/?logined');
}

sub logout {
	my $self = shift;
	$self->session(expires => 1);
	$self->redirect_to('/');
}

1;
