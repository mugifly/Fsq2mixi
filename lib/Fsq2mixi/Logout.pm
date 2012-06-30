package Fsq2mixi::Logout;
use utf8;
use Mojo::Base 'Mojolicious::Controller';


sub logout {
	my $self = shift;
	$self->session(expires => 1);
	$self->redirect_to('/');
}

1;