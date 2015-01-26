use strict;
use warnings;

use Kelp::Test;
use Test::More;
use HTTP::Request::Common;

my $t = Kelp::Test->new( psgi => 'app.psgi' );

# Create a link
$t->request( POST '/', { url => 'http://aa.com' } )->code_is(200);
ok $t->res->content;
ok $t->res->content =~ qr{/([a-zA-Z0-9]+)$};

# Verify
$t->request( GET $1 )
  ->code_is(307)
  ->header_is(Location => 'http://aa.com');

# Expiration
$t->request( POST '/', { url => 'http://aa.com', ttl => 2 } )->code_is(200);
ok $t->res->content;
ok $t->res->content =~ qr{/([a-zA-Z0-9]+)$};
note "sleep 3";
sleep 3;

$t->request( GET $1 )->code_is(404);

done_testing;
