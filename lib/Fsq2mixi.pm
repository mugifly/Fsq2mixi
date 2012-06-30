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
		my $driver = Data::Model::Driver::DBI->new(dsn => 'dbi:SQLite:dbname=db_fsq2mixi.db');
		$db->set_base_driver($driver);
	}
	for my $target ($db->schema_names) {
		my $dbh = $db->get_driver($target)->rw_handle;
		for my $sql ($db->as_sqls($target)) {
			#$dbh->do($sql);
		}
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
	my $mixi_consumer = OAuth::Lite::Consumer->new(
		consumer_key		=> $self->config->{mixi_consumer_key},
		consumer_secret		=> $self->config->{mixi_consumer_secret},
		site				=> q{https://secure.mixi-platform.com},
		access_token_path	=> q{/2/token}
	);
	$self->helper(mixi => sub{return $mixi_consumer});
	
	my $is4sq = 0;
	
	# Routes
	my $r = $self->routes;
	
	$r->route('/login')->to('login#foursquare');
	$r->route('/foursquare_redirect_authpage')->to('login#foursquare_redirect_authpage');
	$r->route('/oauth_callback_fsq')->to('login#foursquare_callback');
	
	$r = $r->bridge->to(
		cb => sub {
			my $self = shift;
			my $fsq_token = $self->session('fsq_token');
			
			if($fsq_token ne ""){
				 my $users = $db->get('user' => {
					where => [
						fsq_token => $fsq_token
					]
				});
				my $r = $users->next;
				if(!defined($r->id)){
					$self->redirect_to('/login');
					return 0;
				}
			}else{
				$self->redirect_to('/login');
				return 0;
			}
			return 1;
		}
	);
	
	$r->route('/logout')->to('logout#logout');
	$r->route('/')->to('user#usermenu');
}

1;
