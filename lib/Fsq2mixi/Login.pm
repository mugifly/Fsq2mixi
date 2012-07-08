package Fsq2mixi::Login;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub mixi_redirect_authpage {
	my $self = shift;
	$self->flash(auth_flg => 'mixiauth-'.$self->config->{mixi_consumer_key});
	my $mixi = Mixi->new('consumer_key'=> $self->config->{mixi_consumer_key}, 'consumer_secret' => $self->config->{mixi_consumer_secret});
	$self->redirect_to($mixi->getRedirectURL());
}

sub mixi_callback {
	my $self = shift;
	if(($self->flash("auth_flg") ne 'mixiauth-'.$self->config->{mixi_consumer_key}) || $self->param('code') eq ""){
		$self->redirect_to('/');
	}
	
	# mixiサーバからアクセストークンを取得
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret});
	my ($mixi_token, $mixi_rtoken) = $mixi->getTokens($self->param('code'));
	
	# セッション情報を取得
	my $fsq_token = $self->session('fsq_token');
	
	# DB上のユーザ情報を更新
	my ($d, ) = $self->db->get('user' => {
		where => [
			fsq_token => $fsq_token
		],
	});
	$d->mixi_token($mixi_token);
	$d->mixi_rtoken($mixi_rtoken);
	$d->update;
	
	$self->redirect_to('/');
}

sub foursquare_redirect_authpage {
	my $self = shift;
	$self->flash(auth_flg => 'fsqauth-'.$self->config->{fsq_client_id});
	$self->redirect_to("https://foursquare.com/oauth2/authenticate?client_id=".$self->config->{fsq_client_id}."&response_type=code&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq");
}

sub foursquare_callback {
	my $self = shift;
	if($self->flash("auth_flg") ne 'fsqauth-'.$self->config->{fsq_client_id} || $self->param("code") eq ""){
		$self->redirect_to('/');
	}
	
	my $ua = $self->ua->new;
	my $token = $ua->get('https://ja.foursquare.com/oauth2/access_token'.
		'?client_id='.$self->config->{fsq_client_id}.
		'&client_secret='.$self->config->{fsq_client_secret}.
		'&grant_type=authorization_code'.
		'&redirect_uri=https://s1.mpnets.net/services/fsq2mixi/oauth_callback_fsq'.
		'&code='.$self->param("code")
	)
	->res->json('/access_token');
	
	
	# ユーザ情報をfoursquareから取得
	my $js = $ua->get('https://api.foursquare.com/v2/users/self?oauth_token='.$token);
	my $fsq_id = $js->res->json('/response/user/id');
	
	# DBにユーザ情報を追加
	$self->db->set('user'=> {
		fsq_token => $token,
		fsq_id => $fsq_id,
		mixi_is_active => 1,
		mixi_is_makemyspot => 1,
		mixi_mode => 'voice'
	});
	
	# セッション保存
	$self->session(fsq_token => $token);
	$self->redirect_to('/');
}

1;
