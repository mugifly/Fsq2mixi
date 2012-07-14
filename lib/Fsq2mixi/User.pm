package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	$self->stash(page => "Home");
	if(defined($self->ownUser) && defined($self->ownUser->{id}) && $self->ownUser->{id} ne ""){
		$self->redirect_to('/');
	}
	$self->session(expires => 1);
	$self->render();
}

sub onesq2mixi {
	my $self = shift;
	$self->stash(page => "Home");
	my $userrow = $self->ownUserRow;
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
		access_token => $userrow->mixi_token,
		refresh_token => $userrow->mixi_rtoken,
	);
	my $resultFlg = -1;
	
	# load latest checkin from DB
	my $checkin = {};
	my $h = $self->db->get('checkin' => {
		where => [
			fsq_id => $self->ownUserRow->fsq_id
		]
	});
	my $r = $h->next;
	if(!defined($r) || !defined($r->id)){
		$checkin = $r->{column_values};
	}
	# post to mixi
	if(defined($checkin) && ($checkin->{mixi_send_status} eq "0" || $checkin->{mixi_send_status} eq "100" )){# unsent or last time is error...
		my $ret = $self->PostToMixi->postToMixi($checkin->{json}, $mixi, $userrow->mixi_mode, $userrow->mixi_is_makemyspot);
		if($ret->{sendFlg} eq 1 || $ret->{sendFlg} eq 2){#Success
			# Update DB user-data
			$r->mixi_token($mixi->{access_token});
			$r->mixi_rtoken($mixi->{refresh_token});
			$r->mixi_latestsend_date(time());
			$r->update;
		}
		$resultFlg = $ret->{sendFlg};
		$self->stash(result => $ret);
	}else{
		$resultFlg = -2;
		$self->stash(result => {});
	}
	
	$self->stash(resultFlg => $resultFlg);
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
	$self->stash(mixiUserName => $mixiUserName);
	if(!defined($mixiUserName) || $mixiUserName eq ""){
		$self->stash(is_mixiLogin => "false");
	}else{
		$self->stash(is_mixiLogin => "true");
		$userrow->mixi_token($mixi->{access_token});
		$userrow->mixi_rtoken($mixi->{refresh_token});
		$userrow->update;
	}
	
	# load Check-in history
	my @histories = ();
	my $h = $self->db->get('checkin' => {
		where => [
			fsq_id => $userrow->fsq_id
		],
		limit => 5,
	});
	while(my $art = $h->next){
		push(@histories, $art->{column_values});
	}
	$self->stash(checkin_histories => \@histories);
	
	# output
	$self->render();
}

1;
