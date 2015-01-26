use strict;
use warnings;

use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;

my $t = Kelp::Test->new( psgi => 'app.psgi' );

# Missing url
$t->request( POST '/' )->code_is(400);

# Bad URL
$t->request( POST '/', { url => '$#@' } )
  ->code_is(400)
  ->json_cmp( { error => { url => ignore() }} );

# Bad expiration
$t->request( POST '/', { url => 'aa.com', ttl => 'asdf' } )
  ->code_is(400)
  ->json_cmp( { error => { ttl => ignore() } } );

# Long expiration
$t->request( POST '/', { url => 'aa.com', ttl => 86400 * 31 } )
  ->code_is(400)
  ->json_cmp( { error => { ttl => ignore() } } );

# Regular request
my $url = $t->app->config('url');
$t->request( POST '/', { url => 'http://aa.com' } )
  ->code_is(200)
  ->content_like(qr{^$url/[a-zA-Z0-9]+$});

# JSON request
$t->request(POST '/', Content_Type => 'application/json', Content => '{"url":"http://aa.com"}')
  ->code_is(200)
  ->json_cmp({ url => re(qr{^$url/[a-zA-Z0-9]+$}), ttl => ignore, expires => ignore });

# Bad JSON content
$t->request(POST '/', Content_Type => 'application/json', Content => 'alabama')
  ->code_is(400);

done_testing;
