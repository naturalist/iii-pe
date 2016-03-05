use strict;
use warnings;

use Kelp::Less;
use Redis;
use Encode::Base58;
use Regexp::Common qw/URI/;
use URI::Heuristic qw(uf_uristr);
use Validate::Tiny ':all';
use Try::Tiny;

module 'JSON';
module 'Template';

#===============================================================
# Constants
# ==============================================================
#
my $URI_RE = qr|$RE{URI}{HTTP}{-scheme=>qr/https?/}|;    # URI regex
my $COUNT  = '.count';                                   # Key for the counter
my $TTL     = 86400;         # Default expiration in seconds
my $MAX_TTL = 86400 * 30;    # Do not keep links older than

#===============================================================
# Variables
#===============================================================
#
my $redis = Redis->new( %{ config('redis') } );

#===============================================================
# Routes
#===============================================================
#

get '/' => sub {
    template 'index';
};

post '/' => sub {
    my $self = shift;
    my $input = ();

    try {
        $input =
          req->is_json
          ? $self->json->decode( req->content )
          : req->parameters;
    };

    my $result = validate(
        $input,
        {
            fields  => [qw/url ttl/],
            filters => [
                qr/.+/ => filter(qw/trim/),
                url    => filter_url()
            ],
            checks => [
                url => [ is_required(), is_url() ],
                ttl => is_ttl()
            ]
        }
    );

    if ( !$result->{success} ) {
        res->code(400);
        return { error => $result->{error} };
    }

    my $url = $result->{data}->{url};
    my $ttl = $result->{data}->{ttl} // $TTL;

    my $key = encode_base58( count() );
    $redis->set( $key, $url );
    $redis->expire( $key, $ttl );

    my $short_url = config('url') . "/$key";
    if ( req->is_json ) {
        return {
            url     => $short_url,
            ttl     => $ttl,
            expires => time + $ttl
        };
    }
    else {
        return $short_url;
    }
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

#=================================================================
# Application
#=================================================================
#
run;

#=================================================================
# Subs
#=================================================================
#
sub count {
    my $count = $redis->get($COUNT) // 0;
    $redis->incr($COUNT);
    return $count;
}

sub filter_url {
    return sub {
        my $val = shift;
        return uf_uristr($val);
    };
}

sub is_url {
    return sub {
        my $val = shift // return;
        return "Invalid url" unless $val =~ $URI_RE;
        return;
    };
}

sub is_ttl {
    return sub {
        my $val = shift // return;
        return "Invalid ttl value" unless $val =~ /^\d+$/;
        return "Can not be more than $MAX_TTL" if $val > $MAX_TTL;
        return;
    };
}

