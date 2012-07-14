package Fsq2mixi::DBColumns;
use strict;
use warnings;
use Data::Model::Schema sugar => 'fsq2mixi';

# User table

column_sugar 'user.id'							=> int => {
		required => 1,
		unsigned => 1,
};
column_sugar 'user.fsq_id'						=> int => {
		required => 0,
		unsigned  => 1,
};
column_sugar 'user.fsq_token'					=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.fsq_name'					=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_token'				=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_name'					=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_mode'					=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_rtoken'				=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_is_makemyspot'		=> int => {
		required => 0,
		unsigned => 1,
};
column_sugar 'user.mixi_is_active'			=> int => {
		required => 0,
		unsigned => 1,
};
column_sugar 'user.mixi_latestsend_text'		=> 'varchar' => {
		required => 0,
		size     => 255,
};
column_sugar 'user.mixi_latestsend_date'		=> int => {
		required => 0,
		unsigned => 1,
		default => sub{
			time()
		},
		inflate => 'DateTime',
};

# Checkin table

column_sugar 'checkin.id' => int => {
		required => 0,
		unsigned => 1,
};

column_sugar 'checkin.fsq_userid' => int => {
		required => 0,
		unsigned => 1,
};

column_sugar 'checkin.json' => 'varchar' => {
		required => 0,
		size => 500,
};

column_sugar 'checkin.date'	=>	int	=> {
		required => 0,
		unsigned => 1,
		default => sub{
			time()
		},
		inflate => 'DateTime',
};

column_sugar 'checkin.mixi_send_status'	=>	int	=> {
		# 0 = Unsent, 1 = Send(mixi-Voice), 2 = Send(mixi-Checkin), 100 = Error
		required => 0,
		unsigned => 1
};

1;
