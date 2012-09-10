package Fsq2mixi::DBSchemas;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema sugar => 'fsq2mixi';
use Fsq2mixi::DBColumns;
use Data::Model::Mixin modules => ['FindOrCreate'];
  
install_model user => schema {
	key 'id';
	unique 'fsq_id';
	unique 'fsq_token';
	
	column 'user.id' => {
		auto_increment => 1 
	};
	column 'user.fsq_id';
	utf8_column 'user.fsq_token';
	utf8_column 'user.fsq_name';
	utf8_column 'user.mixi_token';
	utf8_column 'user.mixi_name';
	utf8_column 'user.mixi_mode';
	column 'user.mixi_is_makemyspot';
	column 'user.mixi_is_active';
	utf8_column 'user.mixi_rtoken';
	utf8_column 'user.mixi_latestsend_text';
	column 'user.mixi_latestsend_date';
};

install_model checkin => schema {
	key 'id';
	
	column 'checkin.id';
	utf8_column 'checkin.name';
	column 'checkin.fsq_id';
	utf8_column 'checkin.json';
	column 'checkin.date';
	column 'checkin.mixi_send_status'
};

1;