use Kelp::Test;
use Test::More;
use HTTP::Request::Common;

my $t = Kelp::Test->new( psgi => 'app.psgi' );

$t->request( POST '/', { url => 'aa.com' } )->code_is(200);
my $json = $t->app->json->decode( $t->res->content );

$t->request( GET $json->{url} )->code_is(307);


done_testing;
