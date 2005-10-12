use Test::More tests => 12;
use strict;
use Socket;

BEGIN { use_ok( 'WWW::HostipInfo' ); }

my $hostip = WWW::HostipInfo->new ();
isa_ok ($hostip, 'WWW::HostipInfo');

my $addr = gethostbyname('www.hostip.info');
my $ip   = inet_ntoa( $addr ) if($addr);


SKIP: { skip "an ip address can't be defined.", 10 unless $ip;

# hope that we get www.hostip.info data contains US.

my $info = $hostip->get_info($ip);

isa_ok($info, 'WWW::HostipInfo::Info');

ok($info->code);
ok($info->city);
ok($info->region);
like($hostip->recent_info->country_name, qr/^.+?[^\s]*$/);
like($info->latitude, qr/^-?[.\d]+$/);
like($info->longitude, qr/^-?[.\d]+$/);
is($hostip->recent_info, $info);

is(WWW::HostipInfo->new($ip)->ip, $ip);

$hostip->ip("");
eval q| $hostip->get_info() |;

like($@, qr/IP address is required/i);

}
