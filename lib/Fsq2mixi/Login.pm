package Fsq2mixi::Login;
use utf8;
use Mojo::Base 'Mojolicious::Controller';


sub foursquare {
	my $self = shift;
	
		$self->render(
		message => 'Foursquareへのログイン'
		
	);
}

sub mixi_redirect_authpage {
	my $self = shift;
	$self->redirect_to("https://mixi.jp/connect_authorize.pl".
		'?client_id='.$self->config->{mixi_consumer_key}.
		'&response_type=code'.
		'&scope=r_voice%20w_voice'.
		'&display=touch'
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
	
	# ユーザ情報をfoursquareから取得
	my $js = $ua->get('https://api.foursquare.com/v2/users/self?oauth_token='.$token);
	my $fsq_id = $js->res->json('/response/user/id');
	
	# DBにユーザ情報を追加
	$self->db->set('user'=> {
		fsq_token => $token,
		fsq_id => $fsq_id
	});
	
	# セッション保存
	$c->session(name => 'Ken');
}

1;
