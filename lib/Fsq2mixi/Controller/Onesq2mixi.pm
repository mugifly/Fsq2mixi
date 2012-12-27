package Fsq2mixi::Controller::Onesq2mixi;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub onesq2mixi {
	my $self = shift;
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
	}elsif(defined($checkin->{id}) && ($checkin->{mixi_send_status} eq 0 || $checkin->{mixi_send_status} eq 100 ||  $checkin->{mixi_send_status} eq 101 )){# unsent or last time is error...
		# Really Post-To-Mixi processing
		my $ret = $self->PostToMixi->postToMixi($checkin->{json}, $mixi, $userrow->mixi_mode, 1);
		if($ret->{sendFlg} eq 1 || $ret->{sendFlg} eq 2){# Success...
			# Update DB user-data
			$userrow->mixi_token($mixi->{access_token});
			$userrow->mixi_rtoken($mixi->{refresh_token});
			$userrow->mixi_latestsend_date(time());
			$userrow->update;
			
			$r->mixi_send_status($ret->{sendFlg});
			$r->update;
		}else{# Error...
			$self->app->log->warn("1sq2mixi-error: ".Mojo::JSON->encode($ret));
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

1;
