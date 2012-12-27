package Fsq2mixi;
#######################################################
# Fsq2mixi
# Check-in to foursquare(4sq), automation-post to mixi.
#######################################################
# Copyright (c) 2012 Masanori Ohgita (http://ohgita.info/).
# This program is free software distributed under the terms of the MIT license.
# See LICENSE.txt for details.
#######################################################

use Mojo::Base 'Mojolicious';
use Validator::Custom;
use Config::Pit;
use DateTime;
use JSON;
use String::Trigram;
use Data::Model::Driver::DBI;

use Test::Mock::LWP::Conditional;

use Fsq2mixi::DBSchemas;
use Fsq2mixi::Model::PostToMixi;
use Mixi;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Initialize router
	my $r = $self->routes;
	
	# Load settings for hypnotoad, etc...
	if(-f 'fsq2mixi.conf'){
		$self->plugin('Config' => {'file' => 'fsq2mixi.conf' });
	}
	
	# Load settings by using Config::Pit
	my $config = pit_get('fsq2mixi');# setting_name of Config::Pit
	$self->config->{proxy} = '';
	$self->helper(config => sub{return $config});
	
	if(!defined($config->{session_expires})){
		# Default session expires
		$config->{session_expires} = 2678400;# 2678400 sec = 31day * 24hour * 60min * 60sec
	}
	
	# Set cookie-settings
	if(defined($config->{secret})){
		$self->secret('fsq2mixi'.$config->{secret});
	}
	
	# Reverse proxy support
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$self->hook('before_dispatch' => sub {
		my $self = shift;
		if ( $self->req->headers->header('X-Forwarded-Host') && defined($config->{basepath})) {
			# Set url base-path (directory path)
			my @basepaths = split(/\//,$self->config->{basepath});
			shift @basepaths;
			foreach my $part(@basepaths){
				if($part eq ${$self->req->url->path->parts}[0]){
					push @{$self->req->url->base->path->parts}, shift @{$self->req->url->path->parts};
				}else{
					last;
				}
			}
		}
	});
	
	# Prepare database & helper
	my $db = Fsq2mixi::DBSchemas->new();
	$self->helper(db => sub{return $db});
	{
		my $dbpath = 'db_fsq2mixi.db';
		if(defined($config->{dbpath}) && $config->{dbpath} ne ""){
			$dbpath = $config->{dbpath};
		}
		if($self->mode eq "test"){# Temporary DB for Test-mode
			$dbpath = "test-".$dbpath;
			if(-e $dbpath){ unlink($dbpath); }
		}
		my $driver = Data::Model::Driver::DBI->new(dsn => 'dbi:SQLite:dbname='.$dbpath);
		$db->set_base_driver($driver);
	}
	for my $target ($db->schema_names) {
		my $dbh = $db->get_driver($target)->rw_handle;
		for my $sql ($db->as_sqls($target)) {
			eval{$dbh->do($sql)};
		}
	}
	
	# Prepare model helper
	my $p2m = Fsq2mixi::Model::PostToMixi->new();
	$self->helper(PostToMixi => sub{return $p2m});
	
	# template stash
	$self->stash(page => "Home");
	
	# Prepare user-data hash & helper
	$self->helper(ownUser => sub{return undef});
	$self->helper(ownUserRow => sub{
		my $self = shift;
		my ($d, ) = $self->db->get('user' => {
			where => [
				id => $self->ownUser->{id} 
			],
		});
		return $d;
	});
	
	# Bridge (for login check)
	$r = $r->bridge->to('bridge#login_check');
	
	# Routes (for not log-in to 4sq , and all-users)
	$r->route('')->to('user#login');
	$r->route('/login')->to('user#login');
	
	$r->route('/about')->to('about#about');
	$r->route('/privacy')->to('about#privacy');
	
	$r->route('/foursquare_pushreceiver')->to('pushreceiver#fsq_checkin_receiver');
	$r->route('/foursquare_redirect_authpage')->to('login#foursquare_redirect_authpage');
	$r->route('/oauth_callback_fsq')->to('login#foursquare_callback');
	
	# Routes (for logged-in users)
	$r->route('/top')->to('user#usermenu');
	$r->route('/mixi_redirect_authpage')->to('login#mixi_redirect_authpage');
	$r->route('/oauth_callback_mixi')->to('login#mixi_callback');
	$r->route('/1sq2mixi')->to('user#onesq2mixi');
	$r->route('/logout')->to('logout#logout');
}

1;
