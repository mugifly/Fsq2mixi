package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	$self->stash(page => "Home");
	if(defined($self->ownUser) && defined($self->ownUser->{id})){
		$self->redirect_to('/');
	}
	$self->render();
}

sub usermenu {
	my $self = shift;
	$self->stash(page => "Home");
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
	if(defined($self->param("mixi_is_makemyspot"))){
		my $mixi_is_makemyspot = $self->param("mixi_is_makemyspot");
		if(($mixi_is_makemyspot eq "true")){
			$userrow->mixi_is_makemyspot(1);
		}elsif($mixi_is_makemyspot eq "false"){
			$userrow->mixi_is_makemyspot(0);
		}
		$userrow->update;
		$self->redirect_to("/");
	}
	if(defined($self->param("mixi_mode"))){
		my $mixi_mode = $self->param("mixi_mode");
		if(($mixi_mode eq "checkin")){
			$userrow->mixi_mode("checkin");
		}elsif($mixi_mode eq "voice"){
			$userrow->mixi_mode("voice");
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
	
	# mixi-checkin - isMakeMySpot?
	if($userrow->mixi_is_makemyspot eq 1){
		$self->stash(mixi_is_makemyspot => "true");
	}else{
		$self->stash(mixi_is_makemyspot => "false");
	}
	
	# post mode
	if($userrow->mixi_mode eq "checkin"){
		$self->stash(mixi_mode => "checkin");
	}else{
		$self->stash(mixi_mode => "voice");
	}
	
	# get mixi user-data
	my $mixiUserName = $mixi->getUser_MixiName();
	#my @a = $mixi->getCheckinSpots("35.6813819444","139.7660838819");
	#$mixi->postCheckin("M2752295","35.6813819444","139.7660838819",$a[0]->{name}->{formatted});
	$self->stash(mixiUserName => $mixiUserName.":");
	if(!defined($mixiUserName) || $mixiUserName eq ""){
		$self->stash(is_mixiLogin => "false");
	}else{
		$self->stash(is_mixiLogin => "true");
		$userrow->mixi_token($mixi->{access_token});
		$userrow->mixi_rtoken($mixi->{refresh_token});
		$userrow->update;
	}
	
	#$mixi->postCheckinSpot("testSpot","+35.6813819444","+139.7660838889","testnow")
	
	# output
	$self->render();
}

1;