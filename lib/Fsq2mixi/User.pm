package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	$self->render();
}

sub usermenu {
	my $self = shift;
	my $user = $self->ownUser;
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
		access_token => $user->{mixi_token},
		refresh_token => $user->{mixi_rtoken},
	);
	
	# mixiのユーザ情報を取得
	my $mixiUserName = $mixi->getUser_MixiName();
	$self->stash(mixiUserName => $mixiUserName);
	if(!defined($mixiUserName) || $mixiUserName eq ""){
		$self->stash(is_mixiLogin => 0);
	}else{
		$self->stash(is_mixiLogin => 1);
	}
	
	# 出力
	$self->render(
		message => 'ユーザーメニュー'
		
	);
}

1;