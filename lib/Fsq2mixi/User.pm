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
	$self->stash(page => "1sq2mixi");
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
			fsq_id => $self->ownUserRow->fsq_id,
		],
		order => [
			{date => 'DESC'}
		],
	});
	my $r = $h->next;
	if(defined($r) && defined($r->id)){
		$checkin = $r->{column_values};
	}
	# post to mixi
	if($self->param("nosend") eq 1){
		# redirect: 1sq2mixi infomation page (no post)
		$self->flash("nosend" => 1);
		$self->redirect_to("/1sq2mixi");
		return 0;
	}elsif($self->flash("nosend") eq 1){
		# 1sq2mixi infomation page (no post)
		$self->stash(result => {});
		$resultFlg = "INFO";
	}elsif($userrow->mixi_token eq ""){
		$self->stash(result => {});
		$resultFlg = "NOT_AUTH";
	}elsif(defined($checkin->{id}) && ($checkin->{mixi_send_status} eq 0 || $checkin->{mixi_send_status} eq 100 )){# unsent or last time is error...
		my $ret = $self->PostToMixi->postToMixi($checkin->{json}, $mixi, $userrow->mixi_mode, 1);
		if($ret->{sendFlg} eq 1 || $ret->{sendFlg} eq 2){#Success
			# Update DB user-data
			$userrow->mixi_token($mixi->{access_token});
			$userrow->mixi_rtoken($mixi->{refresh_token});
			$userrow->mixi_latestsend_date(time());
			$userrow->update;
			
			$r->mixi_send_status($ret->{sendFlg});
			$r->update;
		}else{
			$self->app->log->warn("1sq2mixi-error: ".$ret);
		}
		$self->stash(result => $ret);
		$resultFlg = $ret->{sendFlg};
	}elsif($checkin->{mixi_send_status} eq 1 || $checkin->{mixi_send_status} eq 2){
		$self->stash(result => {});
		$resultFlg = "SENT";
	}else{
		$self->stash(result => {});
		$resultFlg = "HISTORY_NULL";
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
