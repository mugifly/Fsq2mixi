package Mixi;
##################################################
# Mixi - mixiを扱うための超簡易モジュール
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

use strict;
use warnings;
use utf8;

our $VERSION = '1.0.0';

use Carp;

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
	my $noRetry = shift || undef;
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

1;