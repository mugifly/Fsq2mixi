package Mixi;
##################################################
# Mixi - mixiを扱うための超簡易モジュール
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

=head1 SCRIPT NAME

Mixi

=head1 DESCRIPTION

mixiを扱うための超簡易モジュール

=cut

use strict;
use warnings;
use utf8;

our $VERSION = '1.0.0';

use Carp;

use JSON;
use Mojo::UserAgent;
use Mojo::JSON;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{consumer_key} 		= $hash{consumer_key} || "";
	$self->{consumer_secret}	= $hash{consumer_secret} || "";
	$self->{access_token}		= $hash{access_token} || "";
	$self->{refresh_token}		= $hash{refresh_token} || "";
	$self->{ua}					= Mojo::UserAgent->new();
	$self->{ua}->connect_timeout(5);
	$self->{json}				= Mojo::JSON->new();
	
	return $self;
}


sub getUser_MixiName {
	my $self = shift;
	my $u = $self->getProfile();
	my $j = $self->{json}->decode($u);
	return $j->{entry}->{displayName};
}

sub getProfile {
	my $self = shift;
	my $noRetry = shift || 0;
	if($self->{access_token} eq ""){return undef;}
	
	my $res = $self->{ua}->get('https://api.mixi-platform.com/2/people/@me/@self?oauth_token='.$self->{access_token});
	if($res->success){
		return $res->res->body;
	}elsif($noRetry ne 1){
		$self->refreshTokens($self->{refresh_token});
		return $self->getProfile(1);
	}else{
		return undef;
	}
}

sub getRedirectURL {
	my $self = shift;
	return "https://mixi.jp/connect_authorize.pl".
		'?client_id='.$self->{consumer_key}.
		'&response_type=code'.
		'&scope=r_profile%20r_voice%20w_voice%20r_checkin%20w_checkin'.
		'&display=touch';
}

sub refreshTokens {
	my $self = shift;
	my $rToken = shift;
	
	my $res = $self->{ua}->post_form('https://secure.mixi-platform.com/2/token' => 
		{
			client_id =>  		$self->{consumer_key},
			client_secret =>  	$self->{consumer_secret},
			grant_type => 		'refresh_token',
			refresh_token =>	$rToken
		}
	)->res->body;
	
	my $r = $self->{json}->decode($res);
	
	my $aToken = $r->{access_token};
	$rToken = $r->{refresh_token};
	
	if($aToken eq ""){
		return undef;
	}
	
	$self->{access_token} = $aToken;
	$self->{refresh_token} = $rToken;
	return ($aToken, $rToken);
}

sub getTokens {
	my $self = shift;
	my $code = shift;
	
	my $res = $self->{ua}->post_form('https://secure.mixi-platform.com/2/token' => 
		{
			client_id =>  		$self->{consumer_key},
			client_secret =>  	$self->{consumer_secret},
			grant_type => 		'authorization_code',
			redirect_uri =>		'https://s1.mpnets.net/services/fsq2mixi/oauth_callback_mixi',
			code =>				$code
		}
	)->res->body;
	
	my $r = $self->{json}->decode($res);
	
	my $aToken = $r->{access_token};
	my $rToken = $r->{refresh_token};
	
	if($aToken eq ""){
		return undef;
	}
	
	$self->{access_token} = $aToken;
	$self->{refresh_token} = $rToken;
	return ($aToken, $rToken);
}

sub postVoice {
	my $self = shift;
	my $text = shift;
	my $noRetry = shift;
	my $res = $self->{ua}->post_form('https://api.mixi-platform.com/2/voice/statuses/update' => 
		{
			status => $text,
			oauth_token => $self->{access_token}
		}
	);
	
	if($res->success){
		$res = $res->res->body;
		my $r = $self->{json}->decode($res);
		my $postId = $r->{id};
		if($postId ne ""){
			return $postId;
		}else{
			return undef;
		}
	}elsif($noRetry ne 1){
		$self->refreshTokens($self->{refresh_token});
		$self->postVoice($text,1);
	}
}

# postCheckin(SpotId,Lat,Lon,Message)
sub postCheckin{
	my ($self, $spotid, $latitude, $longitude, $message) = @_;
	$self->{ua}->on(start => sub {
		my ($ua, $tx) = @_;
		$tx->req->headers->header('Authorization', 'OAuth '.$self->{access_token});
	});
	my $checkinData = {
		'message'			=> $message,
		'location' => {
			'latitude'		=>	$latitude,
			'longitude'	=> 	$longitude
		}
	};
	my $retry = 0;
	while($retry<=1){
		my $res = $self->{ua}->post('https://api.mixi-platform.com/2/checkins/'.$spotid,JSON->new->encode($checkinData));
		
		if($res->success){
			$res = $res->res->body;
			my $r = $self->{json}->decode($res);
			my $postId = $r->{id};
			if($postId ne ""){
				return $postId;
			}else{
				return undef;
			}
		}else{
			$self->refreshTokens($self->{refresh_token});
		}
		$retry++;
	}
	return undef;
}

# postCheckinSpots(Name,Lat,Lon,Description) - Check-in マイスポット作成
sub postCheckinSpot{
	my ($self, $name, $latitude, $longitude, $description) = @_;
	$self->{ua}->on(start => sub {
		my ($ua, $tx) = @_;
		$tx->req->headers->header('Authorization', 'OAuth '.$self->{access_token});
	});
	my $spotData = {
		'name'			=> $name,
		'location' => {
			'latitude'		=>	$latitude,
			'longitude'	=> 	$longitude
		},
		'description'	=>	$description
	};
	
	my $retry = 0;
	while($retry<=1){
		my $res = $self->{ua}->post('https://api.mixi-platform.com/2/spots/@me/@self',JSON->new->encode($spotData));
		
		if($res->success){
			$res = $res->res->body;
			my $r = $self->{json}->decode($res);
			my $postId = $r->{id};
			if($postId ne ""){
				return $postId;
			}else{
				return undef;
			}
		}else{
			$self->refreshTokens($self->{refresh_token});
		}
		$retry = $retry + 1;
	}
	return undef;
}

# getCheckinSpots(Lat,Lon) - Check-in スポット検索
# (2012年07月現在、マイスポットのみ。)
sub getCheckinSpots{
	my ($self, $latitude,$longitude) = @_;
	my $noRetry = 0;
	my @spots = ();
	my $req_StartPage = 0;
	my $REQ_PERPAGE = 20;
	while(1){
		my $res = $self->{ua}->get('https://api.mixi-platform.com/2/search/spots?oauth_token='.$self->{access_token}.'&count='.$REQ_PERPAGE
			.'&startIndex='.$req_StartPage
			.'&center='.$latitude.','.$longitude
		);
		if($res->success){
			my $r = JSON->new->decode($res->res->body);
			foreach my $s(@{$r->{entry}}){
				push(@spots,$s);
			}
			if(!defined($r->{totalResults}) || ($req_StartPage + $REQ_PERPAGE) >= $r->{totalResults}){
				last;
			}
			$req_StartPage += $REQ_PERPAGE;
		}elsif($noRetry eq 0){
			$self->refreshTokens($self->{refresh_token});
			$noRetry = 1;
		}else{
			last;
		}
	}
	return @spots;
}

1;