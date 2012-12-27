package Fsq2mixi::Pushreceiver;
use utf8;
use Encode;
use Mojo::Base 'Mojolicious::Controller';

# PushReceiver
# for Request (Push from Foursquare-server)

sub fsq_checkin_receiver {
	my $self = shift;
	$self->app->log->fatal("DEBUG:Pushreceiver");
	
	my $param_checkin = $self->param('checkin');
	my $param_secret = $self->param('secret');
	
	$self->app->log->fatal("  param_checkin: $param_checkin");
	
	my $sendFlg = 0;
	
	# verify push-secret
	$self->app->log->fatal("  verify push-secret");
	if($param_secret ne $self->config->{fsq_push_secret}){
		$self->render(status => 401);
		$self->render_json({'result' => 0, 'error_text'=>'push verify failed'});
		return 0;
	}
	
	# extract checkin-data
	$self->app->log->fatal("  extract checkin-data");
	my $checkin = JSON->new->decode($param_checkin);
	my $fsq_id = $checkin->{user}->{id};
	my $fsq_shout = "";
	if(defined($checkin->{shout}) && $checkin->{shout} ne ""){
		$fsq_shout = $checkin->{shout}." ";
	}
	my $fsq_spotName = $checkin->{venue}->{name};
	
	# load user-data
	$self->app->log->fatal("  load user-data");
	my $user;
	my ($r, ) = $self->db->get('user' => {
		where => [
			fsq_id => $fsq_id
		],
	});
	if(!defined($r) || !defined($r->id)){
		$self->render(status => 401);
		$self->render_json({'result' => 0, 'error_text'=>'user not found', 'chk'=> $checkin});
		return 0;
	}else{
		$user = $r->{column_values};
	}
	
	if($user->{mixi_is_active} eq 1 && $user->{mixi_token} ne ""){#send to mixi is enable
	
		# prepare connection for mixi
		$self->app->log->fatal("  Prepare Mixi... mixi_token = $user->{mixi_token}");
		my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
			access_token => $user->{mixi_token},
			refresh_token => $user->{mixi_rtoken},
		);
		
		$self->app->log->fatal("  PostToMixi");
		my $ret = $self->PostToMixi->postToMixi($param_checkin, $mixi, $user->{mixi_mode}, 1);
		if($ret->{sendFlg} eq 1 || $ret->{sendFlg} eq 2){#Success
			# Update DB user-data
			$r->mixi_token($mixi->{access_token});
			$r->mixi_rtoken($mixi->{refresh_token});
			$r->mixi_latestsend_date(time());
			$r->update;
		}else{
			$self->app->log->error("  PostToMixi...Failed:".$ret->{sendFlg});
		}
		
		$self->render_json({
			'result' => $ret->{sendFlg},
			'mixi_postId' => $ret->{postId},
			'name'=> $ret->{name},
			'lat'=> $ret->{latitude},
			'lng'=> $ret->{longitude},
		});
		$sendFlg = $ret->{sendFlg};
	}else{#send to mixi is disable
		$self->app->log->fatal("  #send to mixi is disable");
		$self->render_json({
			'result'	=> -1,
		});
		$sendFlg = 0;
	}
	
	# save checkin to database
	$self->app->log->fatal("  Save checkin to database");
	$self->db->set('checkin'=> {
		'id'					=>	$checkin->{id},
		'name'					=>	$fsq_spotName,
		'fsq_id'			=>	$fsq_id,
		'json'					=>	$param_checkin,
		'date'					=>	time(),
		'mixi_send_status'	=>	$sendFlg,
	});
	
	# auto deletion of old checkin
	$self->app->log->fatal("  auto deletion of old checkin");
	my $h = $self->db->get('checkin' => {
		where => [
			fsq_id => $fsq_id
		],
		limit => 9,
		offset => 9,
		order => [
			{date => 'DESC'}
		],
	});
	if(my $art = $h->next){
		$self->db->delete(
			'checkin' => {
				where => [ id => { '<' => $art->id }, fsq_id => $fsq_id ],
			},
		);
		last;
	}
	
	$self->app->log->fatal("  done - sendFlg: $sendFlg");
	return 1;
}

1;
