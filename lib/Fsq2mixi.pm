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
use Fsq2mixi::DBSchemas;
use Fsq2mixi::Model::PostToMixi;
use Mixi;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Load settings by using Config::Pit
	my $config = pit_get('fsq2mixi');# setting_name of Config::Pit
	$self->helper(config => sub{return $config});
	
	# Set cookie-settings
	$self->secret('fsq2mixi'.$config->{secret});
	
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
	my $user;$user = undef;
	$self->helper(ownUser => sub{return $user});
	$self->helper(ownUserRow => sub{
		my $self = shift;
		my ($d, ) = $self->db->get('user' => {
			where => [
				id => $self->ownUser->{id} 
			],
		});
		return $d;
	});
	
	# Initial Routes (for not log-in to 4sq , and all-users)
	my $r = $self->routes;
	$r->route('/about')->to('about#about');
	
	$r->route('/foursquare_pushreceiver')->to('pushreceiver#fsq_checkin_receiver');
	$r->route('/foursquare_redirect_authpage')->to('login#foursquare_redirect_authpage');
	$r->route('/oauth_callback_fsq')->to('login#foursquare_callback');
	# Bridge (login check)
	$r = $r->bridge->to(
		cb => sub{
			my $self = shift;
			$self->session(expires => time + 604800);
			my $fsq_token = "";
			$user = {};
			if($self->session('fsq_token') ne ""){
				$fsq_token = $self->session('fsq_token');
			}
			
			if($fsq_token ne ""){#token check
				 my $users = $db->get('user' => {
					where => [
						fsq_token => $fsq_token
					]
				});
				my $r = $users->next;
				if(!defined($r) || !defined($r->id)){
					$self->redirect_to("/login");
					if($self->current_route ne "login"){
						$self->redirect_to('/login');
						return 0;
					}
				}else{#found user-data from db
					$user = $r->{column_values};
				}
			}else{#token is null...
				if($self->current_route ne "login"){
					$self->redirect_to('/login');
					return 0;
				}
			}
			return 1;
		}
	);
	$r->route('/login')->to('user#login');
	
	# Routes (for logged-in)
	$r->route('/mixi_redirect_authpage')->to('login#mixi_redirect_authpage');
	$r->route('/oauth_callback_mixi')->to('login#mixi_callback');
	$r->route('/1sq2mixi')->to('user#onesq2mixi');
	$r->route('/logout')->to('logout#logout');
	$r->route('/')->to('user#usermenu');
	$r->route('')->to('user#usermenu');
}

1;
