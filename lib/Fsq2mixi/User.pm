package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	$self->render();
}

sub usermenu {
	my $self = shift;
	my $userrow = $self->ownUserRow;
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
		access_token => $userrow->mixi_token,
		refresh_token => $userrow->mixi_rtoken,
	);
	
	if(defined($userrow->mixi_latestsend_text)){
		$self->stash(mixi_latestsend_text => $userrow->mixi_latestsend_text);
		$self->stash(mixi_latestsend_date => $userrow->mixi_latestsend_date);
	}else{
		$self->stash(mixi_latestsend_text => "-");
		$self->stash(mixi_latestsend_date => "-");
	}
	
	
	# setting change mode
	if(defined($self->param("mixi_is_active"))){
		my $mixi_is_active = $self->param("mixi_is_active");
		if(($mixi_is_active eq "true")){
			$userrow->mixi_is_active(1);
		}elsif($mixi_is_active eq "false"){
			$userrow->mixi_is_active(0);
		}
		$userrow->update;
		$self->redirect_to("/");
	}
	
	# post to mixi - isEnable?
	if($userrow->mixi_is_active eq 1){
		$self->stash(mixi_is_active => "true");
	}else{
		$self->stash(mixi_is_active => "false");
	}
	
	# get mixi user-data
	my $mixiUserName = $mixi->getUser_MixiName();
	$self->stash(mixiUserName => $mixiUserName.":". $mixi->getCheckinSpots());
	if(!defined($mixiUserName) || $mixiUserName eq ""){
		$self->stash(is_mixiLogin => "false");
	}else{
		$self->stash(is_mixiLogin => "true");
	}
	
	# output
	$self->render(
		message => 'ユーザーメニュー'
		
	);
}

1;