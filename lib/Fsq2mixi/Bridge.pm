package Fsq2mixi::Bridge;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

sub login_check {
my $self = shift;
	# Checking Configuration
	if(!defined($self->config->{fsq_client_id}) || !defined($self->config->{mixi_consumer_key})){
		$self->render_text("fsq2mixi Debug: Config::Pit is not configured.");
		$self->app->log->fatal("fsq2mixi Debug: Config::Pit is not configured.");
		return 0;
	}
	
	# Maintenance mode
	if(defined($self->config->{maintain_mode})){
		$self->render(template => 'maintenance');
		return 0;
	}
	
	# Reset user-data helper
	$self->app->helper(ownUser => sub { return undef });
	$self->stash(logined => 0);
	
	if($self->session('fsq_token')){# If client has token ... token check
		 my $users = $self->db->get('user' => {
			where => [
				fsq_token => $self->session('fsq_token')
			]
		});
		my $r = $users->next;
		if(defined($r) && defined($r->id)){ # If found user
			my $user = $r->{column_values};
			$self->app->helper(ownUser => sub{return $user});
			return 1;
		}
	}
	
	#token is null...
	if($self->current_route eq "top" 
		|| $self->current_route eq "mixi_redirect_authpage"
		|| $self->current_route eq "oauth_callback_mixi"
		|| $self->current_route eq "1sq2mixi"
		|| $self->current_route eq "logout"
	){
		$self->redirect_to('/login?tokennull');
		return 0;
	}
	
	return 1;# return true = continue after process
}

1;