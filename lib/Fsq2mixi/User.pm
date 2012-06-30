package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';


sub usermenu {
	my $self = shift;
	$self->stash(is_mixiLogin => 1);
		$self->render(
		message => 'ユーザーメニュー'
		
	);
}

1;