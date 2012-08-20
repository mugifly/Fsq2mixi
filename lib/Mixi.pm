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
use Encode;

our $VERSION = '1.0.0';

use Carp;

use JSON;
use LWP::UserAgent;
use Test::Mock::LWP::Conditional;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{consumer_key} 		= $hash{consumer_key} || "";
	$self->{consumer_secret}	= $hash{consumer_secret} || "";
	$self->{access_token}		= $hash{access_token} || "";
	$self->{refresh_token}		= $hash{refresh_token} || "";
	$self->{ua}					= LWP::UserAgent->new;
	$self->{ua}->timeout(20);
	$self->{json}				= JSON->new;
	
	$self->{isTest}	= 	$hash{isTest} || 0;
	$self->{proxy}	= 	$hash{proxy} || "";
	if($self->{proxy} ne ""){
		$self->{ua}->http_proxy($self->{proxy});
		$self->{ua}->https_proxy($self->{proxy});
	}
	
	return $self;
}


sub getUser_MixiName {
	my $self = shift;
	if($self->{isTest}){return $self->getUser_MixiName_T();} 
	my $u = $self->getProfile();
	my $j = $self->{json}->decode($u);
	return $j->{entry}->{displayName};
}

sub getUser_MixiName_T {
	return "アヤコ";
}

sub getProfile {
	my $self = shift;
	my $noRetry = shift || 0;
	if($self->{access_token} eq ""){return undef;}
	if($self->{isTest}){return $self->getProfile_T();} 
	
	my $res = $self->{ua}->get('https://api.mixi-platform.com/2/people/@me/@self', Authorization => 'OAuth '. $self->{access_token});
	if($res->is_success){
		return Encode::decode_utf8($res->content);
	}elsif($noRetry ne 1){
		$self->refreshTokens($self->{refresh_token});
		return $self->getProfile(1);
	}else{
		return undef;
	}
}

sub getProfile_T {
	my $self = shift;
	my $json = {
		entry => {
				id				=>	"fq7qstgzss9dd",
				displayName	=>	"アヤコ",
				userHash		=>	"9g012dfnwrt6qxbctt9fw86utfg0k7yco6guzox5"
		}		
	};
	return JSON::encode($json);
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
	if($self->{isTest}){return $self->refreshTokens_T($rToken);} 
	
	my $res = Encode::decode_utf8($self->{ua}->post('https://secure.mixi-platform.com/2/token', 
		{
			client_id =>  		$self->{consumer_key},
			client_secret =>  	$self->{consumer_secret},
			grant_type => 		'refresh_token',
			refresh_token =>	$rToken
		}
	)->content);
	
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

sub refreshTokens_T {
	my $self = shift;
	my $rToken = shift;
	return "TEST-ACCESS-TOKEN_REF-".time;
}

sub getTokens {
	my $self = shift;
	my $code = shift;
	if($self->{isTest}){return $self->getTokens_T($code);} 
	
	my $res = Encode::decode_utf8($self->{ua}->post('https://secure.mixi-platform.com/2/token',
		{
			client_id =>  		$self->{consumer_key},
			client_secret =>  	$self->{consumer_secret},
			grant_type => 		'authorization_code',
			redirect_uri =>		'https://s1.mpnets.net/services/fsq2mixi/oauth_callback_mixi',
			code =>				$code
		}
	)->content);
	
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

sub getTokens_T {
	my $self = shift;
	my $code = shift;
	return "TEST-ACCESS-TOKEN_FST-".time;
}

sub postVoice {
	my $self = shift;
	my $text = shift;
	my $noRetry = shift;
	if($self->{isTest}){return $self->postVoice_T($text);} 
	my $res = $self->{ua}->post('https://api.mixi-platform.com/2/voice/statuses/update',
		{
			status => $text,
			oauth_token => $self->{access_token}
		}
	);
	
	if($res->is_success){
		$res = Encode::decode_utf8($res->content);
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

sub postVoice_T {
	my $self = shift;
	my $text = shift;
	if($text ne ""){
		return time;
	}else{
		return undef;
	}
}

# postCheckin(SpotId,Lat,Lon,Message)
sub postCheckin{
	my ($self, $spotid, $latitude, $longitude, $message) = @_;
	my $checkinData = {
		'message'			=> $message,
		'location' => {
			'latitude'		=>	$latitude,
			'longitude'	=> 	$longitude
		}
	};
	my $retry = 0;
	while($retry<=1){
		my $res = $self->{ua}->post('https://api.mixi-platform.com/2/checkins/'.$spotid,
			Authorization	=> 'OAuth '.$self->{access_token},
			Content_Type    => 'application/json',
			Content 		=> JSON->new->utf8(1)->encode($checkinData)
		);
		
		if($res->is_success){
			$res = Encode::decode_utf8($res->content);
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
		my $res = $self->{ua}->post('https://api.mixi-platform.com/2/spots/@me/@self',
			Authorization	=> 'OAuth '.$self->{access_token},
			Content_Type    => 'application/json',
			Content 		=> JSON->new->utf8(1)->encode($spotData)
		);
		
		if($res->is_success){
			$res = Encode::decode_utf8($res->content);
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
	if($latitude eq "" || $longitude eq ""){
		return undef;
	}
	if($self->{isTest}){return $self->getCheckinSpots_T($latitude,$longitude);}
	my @spots = ();
	my $req_StartPage = 0;
	my $REQ_PERPAGE = 20;
	while(1){
		my $res = $self->{ua}->get('https://api.mixi-platform.com/2/search/spots'
				.'?count='.$REQ_PERPAGE
				.'&startIndex='.$req_StartPage
				.'&center='.$latitude.','.$longitude,
			Authorization => 'OAuth '. $self->{access_token}
		);
		if($res->is_success){
			my $r = JSON->new->decode(Encode::decode_utf8($res->content));
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

sub getCheckinSpots_T {
	my @arr = ();
	my $json = {
		id		=>	0,
		name	=>	{
			formatted =>	"コーヒー専門店 銀座３丁目店"
		},
		address=>	{
			formatted	=>	"〒104-0061 東京都中央区銀座３丁目７-１"
		},
		location=> {
			latitude	=>	"37.416343",
			longitude	=>	"-122.153013"
		},
		description=>	"ここに店舗の説明文が入ります"
	};
	push(@arr,$json);
	return @arr;
}

1;