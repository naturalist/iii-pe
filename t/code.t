use Kelp::Test;
use Test::More;
use HTTP::Request::Common;

my $t = Kelp::Test->new( psgi => 'app.psgi' );

$t->request( POST '/', { url => 'aa.com' } )->code_is(200);
my $json = $t->app->json->decode( $t->res->content );

ok $json->{url} =~ qr{/([a-zA-Z0-9]+)$};
$t->request( GET $1 )->code_is(307);


done_testing;
