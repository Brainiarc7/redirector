#
#  canonicalise (normalize) a URL
#  http://tools.ietf.org/html/rfc3986#section-6.2
#
use URI;

sub c14n_url {
    my ($url, $allow_query_string) = @_;

    # all our nginx location and map matches are case-insensitive
    # ordinarily a bad idea for resources, this removes a lot of duplicate mappings
    $url = lc($url);

    my $uri = URI->new($url);
    $url = URI->new($url)->canonical;

    # protocol should be http
    $url =~ s/^https/http/;

    # remove query_string
    unless ($allow_query_string) {
        $url =~ s/\?.*$//;
    }

    # remove fragment identifier
    $url =~ s/\#.*$//;

    # remove trailing insignificant characters
    $url =~ s/[\?\/\#]*$//;

    # escape characters problematic in CSV
    $url =~ s/"/%22/g;
    $url =~ s/'/%27/g;
    $url =~ s/,/%2C/g;

    # escape some characters problematic in an nginx regex
    $url =~ s/\|/%7C/g;
    $url =~ s/\[/%5B/g;
    $url =~ s/\]/%5D/g;

    return $url;
}

1;
