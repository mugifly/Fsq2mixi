package Fsq2mixi::Pushreceiver;
use utf8;
use Mojo::Base 'Mojolicious::Controller';

sub fsq_checkin_receiver {
	my $self = shift;
	
	my $user = $self->ownUser;
	my $mixi = Mixi->new(consumer_key=> $self->config->{mixi_consumer_key}, consumer_secret => $self->config->{mixi_consumer_secret},
		access_token => $user->{mixi_token},
		refresh_token => $user->{mixi_rtoken},
	);
	my $json  = Mojo::JSON->new;
	
	my $param_checkin = $self->param('checkin');
	my $param_secret = $self->param('secret');
	$mixi->postVoice("これはテストです。");
	if($param_secret ne $self->config->{fsq_push_secret}){
		$self->render(status => 401);
	}
	$self->render_json({
		'result' => 0
	});
	
	
	
	return 0;
}

1;
