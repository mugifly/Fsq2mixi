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
column_sugar 'user.mixi_token'
	=> 'varchar' => {
		required => 0,
		size     => 255,
};
1;