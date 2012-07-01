package Fsq2mixi::DBColumns;
use strict;
use warnings;
use Data::Model::Schema sugar => 'fsq2mixi';

column_sugar 'user.id'
	=> int => {
		required => 1,
		unsigned => 1,
};
column_sugar 'user.fsq_id'
	=> int => {
		required => 0,
		unsigned  => 1,
};
column_sugar 'user.fsq_token'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.fsq_name'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_token'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_name'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_rtoken'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_is_active'
	=> int => {
		required => 0,
		unsigned => 1,
};
column_sugar 'user.mixi_latestsend_text'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_latestsend_date'
	=> int => {
		required => 0,
		unsigned => 1,
		default => sub{
			time()
		},
		inflate => sub{ #DB -> Object
			my $epoch_sec = shift;
			DateTime->from_epoch( epoch => $epoch_sec );
		},
		deflate => sub{#Object -> DB
			ref($_[0]) && $_[0]->isa('DateTime') ? $_[0]->epoch : $_[0];
		}
		# ref: http://perl-users.jp/articles/advent-calendar/2009/data-model/11.html
};
1;