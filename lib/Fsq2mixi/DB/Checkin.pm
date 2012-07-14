package Fsq2mixi::DB::Checkin;
use strict;
use warnings;
use base 'Data::Model';
use Data::Model::Schema sugar => 'fsq2mixi';
use Fsq2mixi::DBColumns;
  
install_model checkin => schema {
	key 'id';
	
	column 'checkin.id';
	column 'checkin.fsq_userid';
	utf8_column 'checkin.json';
	column 'checkin.date';
};
1;