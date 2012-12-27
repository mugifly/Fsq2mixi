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
use Config::Pit;
use DateTime;
use Data::Model::Driver::DBI;
use JSON;
use String::Trigram;
use Test::Mock::LWP::Conditional;
use Validator::Custom;

use Fsq2mixi::DBSchemas;
use Fsq2mixi::Model::PostToMixi;
use Mixi;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Initialize router
	my $r = $self->routes;
	
	# Set namespace
	$r = $r->namespaces(['Fsq2mixi::Controller']);
	
	# Load settings for hypnotoad, etc...
	$self->plugin('Config' => {'file' => 'fsq2mixi.conf' }) if (-f 'fsq2mixi.conf');
	
	# Load settings by using Config::Pit
	my $config = pit_get('fsq2mixi');# setting_name of Config::Pit
	$self->helper(config => sub{return $config});
	
	# Set session expires
	$config->{session_expires} = 2678400 unless defined($config->{session_expires});  
		# Default = 2678400 sec ( 31day * 24hour * 60min * 60sec )
	
	# Set cookie-secret
	$self->secret('fsq2mixi'.$config->{secret}) if defined($config->{secret});
	
	# Reverse proxy support
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$self->hook('before_dispatch' => sub {
		my $self = shift;
		if ( $self->req->headers->header('X-Forwarded-Host') && defined($config->{basepath})) {
			# Set url base-path (directory path)
			my @basepaths = split(/\//,$config->{basepath});	shift @basepaths;
			foreach my $part(@basepaths){
				if($part eq ${$self->req->url->path->parts}[0]){ push @{$self->req->url->base->path->parts}, shift @{$self->req->url->path->parts};	
				} else { last; }
			}
		}
	});
	
	# Prepare database
	my $db = Fsq2mixi::DBSchemas->new();
	{
		my $dbpath;
		if(defined($config->{dbpath})){# Set database file
			$dbpath = $config->{dbpath};
		}else{# Default database file
			$dbpath = 'db_fsq2mixi.db'
		}
		if($self->mode eq "test"){# Temporary DB for Test-mode
			$dbpath = "test-".$dbpath; if(-e $dbpath){ unlink($dbpath); }
		}
		my $driver = Data::Model::Driver::DBI->new(dsn => 'dbi:SQLite:dbname='.$dbpath);
		$db->set_base_driver($driver);
	}
	for my $target ($db->schema_names) {
		my $dbh = $db->get_driver($target)->rw_handle;
		for my $sql ($db->as_sqls($target)) { eval{$dbh->do($sql)};	}
	}
	
	# Set database helper
	$self->attr(db => sub{return $db});
	$self->helper('db' => sub { shift->app->db });
	
	# Prepare model helper
	my $p2m = Fsq2mixi::Model::PostToMixi->new();
	$self->helper(PostToMixi => sub{return $p2m});
	
	# Bridge (for authorization)
	$r = $r->bridge->to('bridge#login_check');
	
	# Routes (for not log-in to 4sq , and all-users)
	$r->route('')->to('top#guest');
	$r->route('/docs/about')->to('docs#about');
	$r->route('/docs/privacy')->to('docs#privacy');
	$r->route('/session/oauth_foursquare_redirect')->to('session#oauth_foursquare_redirect');
	$r->route('/session/oauth_foursquare_callback')->to('session#oauth_foursquare_callback');
	
	$r->route('/pushreceiver/foursquare_checkin')->to('pushreceiver#foursquare_checkin');
	
	# Routes (for logged-in users)
	$r->route('/top')->to('top#user');
	$r->route('/session/oauth_mixi_redirect')->to('session#oauth_mixi_redirect');
	$r->route('/session/oauth_mixi_callback')->to('session#oauth_mixi_callback');
	$r->route('/1sq2mixi')->to('onesq2mixi#onesq2mixi');
	$r->route('/session/logout')->to('session#logout');
}

1;
