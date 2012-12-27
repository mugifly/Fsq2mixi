package Fsq2mixi::Controller::Docs;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub about {
	my $self = shift;
	$self->render();
}

sub privacy {
	my $self = shift;
	$self->render();
}

1;