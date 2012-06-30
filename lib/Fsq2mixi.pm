package Fsq2mixi;
use Mojo::Base 'Mojolicious';
use OAuth::Lite::Consumer;
use JSON;
use Config::Pit;
use Fsq2mixi::DB::User;
use Data::Model::Driver::DBI;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Config::Pitで設定を取得
	my $config = pit_get("fsq2mixi");
	$self->helper(config => sub{return $config});
	
	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');
	
	# データベースの準備
	my $db = Fsq2mixi::DB::User->new();
	$self->helper(db => sub{return $db});
	{
		my $driver = Data::Model::Driver::DBI->new(dsn => 'dbi:SQLite:dbname=fsq2mixi_db.db');
		$db->set_base_driver($driver);
	}
	
	# OAuth Consumerの準備
	my $fsq_consumer = OAuth::Lite::Consumer->new(
		consumer_key		=> $self->config->{fsq_client_id},
		consumer_secret		=> $self->config->{fsq_client_secret},
		site				=> q{https://ja.foursquare.com},
		access_token_path	=> q{/oauth2/access_token},
		authorize_path		=> q{/oauth2/access_token},
	);
	$self->helper(fsq => sub{return $fsq_consumer});
	
	
	# Routes
	my $r = $self->routes;
	
	# Normal route to controller
	$r->route('/')->to('login#foursquare');
	$r->route('/foursquare_redirect_authpage')->to('login#foursquare_redirect_authpage');
	$r->route('/oauth_callback_fsq')->to('login#foursquare_redirect_callback');
}

1;
