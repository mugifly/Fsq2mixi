package Fsq2mixi::Model::PostToMixi;
use utf8;
use Encode;
use JSON;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	return $self;
}

sub postToMixi{
	my ($self, $json, $mixi, $mixi_mode, $mixi_is_makemyspot) = @_;
	
	# extract checkin-data
	my $checkin = JSON->new->decode($json);
	my $fsq_id = $checkin->{user}->{id};
	my $fsq_shout = "";
	if(defined($checkin->{shout}) && $checkin->{shout} ne ""){
		$fsq_shout = $checkin->{shout}." ";
	}
	my $fsq_spotName = $checkin->{venue}->{name};
	
	my $ret = {
		"name"			=>	$fsq_spotName,
		"isNewSpot"	=>	0,
		"latitude"		=>	$checkin->{venue}->{location}->{lat},
		"longitude"	=>	$checkin->{venue}->{location}->{lng},
		"postId"		=>	"",
		"spotName"		=>	$fsq_spotName,
		"id"			=>	$fsq_id,
		"sendFlg"		=>	0, # 1 = Success(mixiVoice), 2 = Success(mixiCheck-in), 100 = Failed
		"error"		=> "",
	};
	my $latitude = $ret->{latitude};
	my $longitude = $ret->{longitude};
	
	if($mixi_mode eq "checkin"){ # mixi-checkin mode
		my $spotId = "";
		
		# search mixi-checkin-spots
		my @spots = $mixi->getCheckinSpots($latitude,$longitude);
		foreach my $spot(@spots){
			my $name = $spot->{name}->{formatted};
			# spot-name compare
			if(String::Trigram::compare($fsq_spotName, $name) >= 0.8){
				$ret->{spotId} = $spot->{id};
				last;
			}				
		}
		if($spotId eq ""){# not existing mixi-check-in-spot...
			if($mixi_is_makemyspot eq 1){ 
				# make new spot
				for (my $retry = 0; $retry <= 1; $retry++) {
					eval{
						$spotId = $mixi->postCheckinSpot($fsq_spotName,$latitude,$longitude,"");
					};
					if ($@ && $@ =~ /parameter_over_capacity/) {
						# Delete old spots
						my @spots = $mixi->getMyCheckinSpots();
						@spots = reverse(@spots);
						for (my $i = 0; $i < 10; $i++) {
							my $spot = $spots[$i];
							my $id = $spot->{id};
							$mixi->deleteCheckinSpot($id);
						}
					} elsif($@) {
						$ret->{error} = $@;
					} else {
						last;
					}
				}
			}
		}
		if($ret->{error} ne ""){
			# Do not anyting
		}elsif($spotId eq ""){
			# SpotId is null...
			$ret->{error} = "spotId is null";
		}else{
			# post check-in
			my $mixi_postId = $mixi->postCheckin($spotId,$latitude,$longitude,$fsq_shout."from foursquare (Fsq2mixi)");
			if($mixi_postId eq undef){# failed
				$ret->{sendFlg} = 100;
				$ret->{error} = "Post checkin failed";
			}else{ # success
				$ret->{sendFlg} = 2;
			}
			$ret->{postId} = $mixi_postId;
		}
	}else{ # mixi-voice mode
		# make a status-text
		my $statusText = "";
		if($fsq_shout ne ""){
			$statusText = $fsq_shout
			.'(@ ' . $fsq_spotName. ")"
			.' (from foursquare (Fsq2mixi))';
		}else{
			my $addr = "";
			if($checkin->{venue}->{location}->{city} ne "" && $checkin->{venue}->{location}->{state} ne ""){
				$addr = $checkin->{venue}->{location}->{city} . ", " . $checkin->{venue}->{location}->{state};
			}elsif($checkin->{venue}->{location}->{city} ne ""){
				$addr = $checkin->{venue}->{location}->{city};
			}elsif($checkin->{venue}->{location}->{state} ne ""){
				$addr = $checkin->{venue}->{location}->{state};
			}
			if($addr ne ""){
				$addr = " (".$addr.")";
			}
			
			$statusText = "I'm at "
			.$fsq_spotName
			.$checkin->{venue}->{location}->{name}.$addr
			.' (from foursquare (Fsq2mixi))';
		}
		
		# send to mixi
		my $mixi_postId = $mixi->postVoice($statusText);
		if($mixi_postId eq undef){# failed	
			$ret->{sendFlg} = 101;
				$ret->{error} = "Post voice failed";
		}else{ # success
			$ret->{sendFlg} = 1;
		}
		$ret->{postId} = $mixi_postId;
	}
	
	return ($ret);
}

1;
