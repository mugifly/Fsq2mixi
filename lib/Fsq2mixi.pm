package Fsq2mixi;
use Mojo::Base 'Mojolicious';
use OAuth::Lite::Consumer;
use JSON;
use Config::Pit;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Config::Pitで設定を取得
	my $config = pit_get("fsq2mixi");
	$self->helper(config => sub{return $config});
	
	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');
	
	# Routes
	my $r = $self->routes;
	
	# Normal route to controller
	$r->route('/')->to('login#foursquare');
	$r->route('/foursquare_redirect_authpage')->to('login#foursquare_redirect_authpage');
	$r->route('/oauth_callback_fsq')->to('login#foursquare_redirect_callback');
}

1;
