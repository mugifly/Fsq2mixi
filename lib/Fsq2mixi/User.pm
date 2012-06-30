package Fsq2mixi::User;
use utf8;
use Mojo::Base 'Mojolicious::Controller';


sub usermenu {
	my $self = shift;
	
		$self->render(
		message => 'ユーザーメニュー'
		
	);
}