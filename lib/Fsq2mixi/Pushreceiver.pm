package Fsq2mixi::Pushreceiver;
use utf8;
use Encode;
use Mojo::Base 'Mojolicious::Controller';

# PushReceiver
# for Request (Push from Foursquare-server)

sub fsq_checkin_receiver {
	my $self = shift;
	
	my $param_checkin = $self->param('checkin');
	my $param_secret = $self->param('secret');
	
	# verify push-secret
	if($param_secret ne $self->config->{fsq_push_secret}){
		$self->render(status => 401);
		$self->render_json({'result' => 0, 'error_text'=>'push verify failed'});
		return 0;
	}
	
	# extract checkin-data
	my $checkin = JSON->new->decode($param_checkin);
	my $fsq_id = $checkin->{user}->{id};
	my $fsq_shout = "";
	if(defined($checkin->{shout}) && $checkin->{shout} ne ""){
		$fsq_shout = Encode::decode('UTF-8',$checkin->{shout})." ";
	}
	my $fsq_spotName = $checkin->{venue}->{name};
	
	# load user-data
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
	
	if($user->{mixi_is_active} eq 1){#send to mixi is enable
		# prepare connection for mixi
		my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
			access_token => $user->{mixi_token},
			refresh_token => $user->{mixi_rtoken},
		);
		
		if($user->{mixi_mode} eq "checkin"){ # mixi-checkin mode
			my $latitude = $checkin->{venue}->{location}->{lat};
			my $longitude = $checkin->{venue}->{location}->{lng};
			
			my $isNewSpot = 0;
			my $spotId = "";
			
			# search mixi-checkin-spots
			my @spots = $mixi->getCheckinSpots($latitude,$longitude);
			foreach my $spot(@spots){
				my $name = Encode::decode('UTF-8',$spot->{name}->{formatted});
				# spot-name compare
				if(String::Trigram::compare($fsq_spotName, $name) >= 0.8){
					$spotId = $spot->{id};
					last;
				}				
			}
			
			if($spotId eq ""){# not existing mixi-check-in-spot... 
				# make new spot
				$spotId = $mixi->postCheckinSpot($fsq_spotName,$latitude,$longitude,"");
				$isNewSpot = 1;
			}
			
			# post check-in
			my $mixi_postId = $mixi->postCheckin($spotId,$latitude,$longitude,$fsq_shout."from foursquare (Fsq2mixi)");
			if($mixi_postId eq undef){# failed
				
			}else{ # success
				# Update DB user-data
				$r->mixi_latestsend_date(time());
				$r->mixi_latestsend_text("[mixiCheckin] ".$fsq_spotName." ".$fsq_shout."from foursquare (Fsq2mixi). (SpotId=$spotId,Lat=$latitude,Lng=$longitude,isNewMySpot=$isNewSpot)");
				$r->mixi_token($mixi->{access_token});
				$r->mixi_rtoken($mixi->{refresh_token});
				$r->update;
			}
			
			$self->render_json({
				'result' => 1,
				'mixi_checkin_id' => $mixi_postId,
				'mixi_spotid' => $spotId,
				'name'=> $fsq_spotName,
				'lat'=> $latitude,
				'lng'=> $longitude
			});
		}else{ # mixi-voice mode
			# make a status-text
			my $statusText = "";
			if($fsq_shout ne ""){
				$statusText = $fsq_shout
				.'(@ ' . $fsq_spotName. ")"
				.' (from foursquare (Fsq2mixi))';
			}else{
				$statusText = "I'm at "
				.$fsq_spotName
				.$checkin->{venue}->{location}->{name}." ("
				.$checkin->{venue}->{location}->{city}.", "
				.$checkin->{venue}->{location}->{state}.")"
				.' (from foursquare (Fsq2mixi))';
			}
			
			# send to mixi
			my $mixi_postId = $mixi->postVoice($statusText);
			if($mixi_postId eq undef){# failed	
				
			}else{ # success
				# Update DB user-data
				$r->mixi_latestsend_date(time());
				$r->mixi_latestsend_text($statusText);
				$r->mixi_token($mixi->{access_token});
				$r->mixi_rtoken($mixi->{refresh_token});
				$r->update;
			}
			
			$self->render_json({
				'result' => 1,
				'mixi_voice_id' => $mixi_postId,
				'name'=> $fsq_spotName
			});
		}
	}else{# send is disable
		$self->render_json({
			'result' => -1
		});
	}
	return 1;
}

1;
