# Test for Mixi Module (only sample-return methods for External tests)
# Mixiモジュール(モジュール呼び出し元プログラムの自動テストを書くためのサンプルを返す関数郡のみ)をテストします

use Mojo::Base -strict;
use Test::More tests => 8;
use utf8;
use JSON;

# Module use check
use_ok("Mixi");

# Inialize module instance
my $mixi = Mixi->new(
	"consumer_key"=> "TEST",
	"isTest" => 1		# mode for External tests
 );

# Methods existence check
can_ok($mixi, 'getUser_MixiName','getRedirectURL','refreshTokens','getTokens','postVoice','postCheckin','postCheckinSpot','getCheckinSpots');

# Test for getUser_MixiName()
is($mixi->getUser_MixiName(),'アヤコ');#return = MixiName

# Test for getRedirectURL()
like($mixi->getRedirectURL(), qr|https\://mixi\.jp/connect_authorize\.pl\?client_id=TEST\&response_type=code\&scope=.+\&display=touch|);#return = URL

# Test for refreshTokens()
like($mixi->refreshTokens("TEST-REFRESH-TOKEN"), qr/\S+/);#return = AccessToken

# Test for getTokens()
like($mixi->getTokens("TEST-AUTH-CODE"), qr/\S+/);#return = AccessToken

# Test for postVoice()
like($mixi->postVoice("test-message"), qr/\d+/);#return = postId

# Test for postCheckin()

# Test for postCheckinSpot()

# Test for getCheckinSpots()
my @arr = $mixi->getCheckinSpots("37.416343","-122.153013");
my $json = $arr[0];
is($json->{name}->{formatted}, "コーヒー専門店 銀座３丁目店");


