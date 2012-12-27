package Fsq2mixi::Controller::Top;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub guest {
	my $self = shift;
	if ( defined($self->ownUser) && defined($self->ownUser->{id}) ) {
		$self->redirect_to("/top");
		return;
	}
	$self->render();
}

sub user {
	my $self = shift;
	
	if(defined($self->flash("message_info"))){
		$self->stash("message_info", $self->flash("message_info"));
	}
	
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
	if(defined($userrow->mixi_token) && $userrow->mixi_token ne ""){
		eval{
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
		};
		if($@){
			$self->stash("message_error", "mixiからのアカウント情報取得に失敗しました。再度、[mixiへのログイン]ボタンから認証してください。");
			$self->app->log->error("Usermenu-error: ".$@);
			$self->stash(is_mixiLogin => "false");
			$self->stash(mixiUserName => "");
		}
	}else{
		$self->stash(is_mixiLogin => "false");
		$self->stash(mixiUserName => "");
	}
	
	# load Check-in history
	my @histories = ();
	my $h = $self->db->get('checkin' => {
		where => [
			fsq_id => $userrow->fsq_id
		],
		limit => 5,
		order => [
			{date => 'DESC'}
		],
	});
	while(my $art = $h->next){
		push(@histories, $art->{column_values});
	}
	$self->stash(checkin_histories => \@histories);
	
	# output
	$self->render();
}

1;
