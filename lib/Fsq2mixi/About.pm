package Fsq2mixi::About;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub about {
	my $self = shift;
	$self->render();
}
1;