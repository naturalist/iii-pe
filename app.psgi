use Kelp::Less;
use Redis;
use Encode::Base58;
use Regexp::Common qw/URI/;
use URI;

module 'JSON';

# Key for the counter
my $COUNT = '.count';

# URI regex
my $URI_RE = qr|$RE{URI}{HTTP}{-scheme=>qr/https?/}|;

# Default expiration in seconds
my $EXPIRE = 86400;

# Do not keep links older than
my $MAX_EXPIRE = 86400 * 30;


my $redis  = Redis->new;

post '/' => sub {
    my $uri = canonical( param('url') // '' )->as_string;
    my $expire = param('expire') // $EXPIRE;

    if ( $uri !~ qr{^http:} ) {
        $uri = 'http://' . $uri;
    }

    if ( $uri !~ $URI_RE ) {
        res->code(400);
        return { error => "Bad or missing url param" };
    }

    if ( $expire > $MAX_EXPIRE ) {
        res->code(400);
        return { error => "Expiration can not be more than $MAX_EXPIRE" };
    }

    my $key = encode_base58( count() );
    $redis->set( $key, $uri );
    $redis->expire( $key, $expire );

    return { url => config('url') . "/$key" };
};

get '/:code' => {
    check => { code => qr{[a-zA-Z0-9]+} },
    to    => sub {
        my ( $self, $code ) = @_;
        if ( my $url = $redis->get($code) ) {
            res->redirect_to( $url, {}, 307 );
        }
        else {
            res->render_404;
        }
    }
};

run;

sub canonical {
    my $uri = URI->new(shift, 'http');
    return $uri->canonical;
}

sub count {
    my $count = $redis->get($COUNT) // 0;
    $redis->incr($COUNT);
    return $count;
}
