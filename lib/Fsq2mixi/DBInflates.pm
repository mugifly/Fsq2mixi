package Fsq2mixi::DBInflates;
use strict;
use warnings;
use Data::Model::Schema::Inflate;

use DateTime;

# Inflates ad Deflates
inflate_type DateTime => {
	inflate => sub { # DB -> Object
		my $epoch_sec = shift;
		DateTime->from_epoch( epoch => $epoch_sec );
	},
	deflate => sub { # Object -> DB
		ref($_[0]) && $_[0]->isa('DateTime') ? $_[0]->epoch : $_[0];
	},
	# ref: http://perl-users.jp/articles/advent-calendar/2009/data-model/11.html
};

1;


