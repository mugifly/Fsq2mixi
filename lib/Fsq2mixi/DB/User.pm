package Fsq2mixi::DB::User;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema sugar => 'fsq2mixi';
use Fsq2mixi::DBColumns;
  
install_model user => schema {
	key 'id';
	
	column 'user.id' => {
		auto_increment => 1 
	};
	column 'user.fsq_id';
	utf8_column 'user.fsq_token';
	utf8_column 'user.mixi_token';
};
1;