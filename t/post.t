use Kelp::Test;
use Test::More;
use HTTP::Request::Common;

my @bad_urls = qw{
    .com
    @$#
};

my @good_urls = qw{
    www.aa
    aa.com
    a.c
    https://ww.com
};

my $t = Kelp::Test->new( psgi => 'app.psgi' );

# Bad url
$t->request( POST '/' )->code_is(400);
for my $url (@bad_urls) {
    $t->request( POST '/', { url => $url } )->code_is(400, $url);
}

# Bad expiration
$t->request( POST '/', { url => 'aa.com', expire => 100_000_000 } )->code_is(400);

for my $url (@good_urls) {
    $t->request( POST '/', { url => $url } )
      ->code_is(200, $url);
}

done_testing;
