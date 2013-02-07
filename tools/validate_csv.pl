#!/usr/bin/env perl

#
#  validate CSV file format
#
use v5.10;
use strict;
use warnings;

use Test::More;
use Text::CSV;
use HTTP::Request;
use LWP::UserAgent;
use URI;

my $filename = shift;
my $domain = shift // "";
my $whitelist_filename = shift // "data/whitelist.txt";
my $http_only = 1;
my %whitelist = ();

load_whitelist($whitelist_filename);

test_file($filename);

done_testing();

exit;

sub test_file {
    my $filename = shift;
    my $csv = Text::CSV->new({ binary => 1 }) or die "Cannot use CSV: " . Text::CSV->error_diag();

    open(my $fh, "<", $filename) or die "$filename: $!";

    my $names = $csv->getline($fh);
    $csv->column_names(@$names);

    while (my $row = $csv->getline_hr($fh)) {
        test_row($row);
    }
}

sub test_row {
    my $row  = shift;

    my $old_url = $row->{'Old Url'} // '';
    my $new_url = $row->{'New Url'} // '';
    my $status = $row->{'Status'} // '';

    my $old_uri = check_url('Old Url', $old_url);

    my $scheme = $old_uri->scheme;

    is($scheme, 'http', "Old Url scheme [$scheme] must be [http] line $.") if ($http_only);

    ok($old_url =~ m{^https?://$domain}, "Old Url [$old_url] domain not [$domain] line $.");

    if ( "301" eq $status) {
        my $new_uri = check_url('New Url', $new_url);
        my $host = $new_uri->host;
        ok($whitelist{$host}, "New Url [$new_url] host [$host] not whiltelist line $.");
    } elsif ( "410" eq $status) {
        ok($new_url eq '', "unexpected New Url [$new_url] for 410 line $.");
    } elsif ( "200" eq $status) {
        ok($new_url eq '', "unexpected New Url [$new_url] for 200 line $.");
    } else {
       fail("invalid Status [$status] for Old Url [$old_url] line $.");
    }
}

sub check_url {
    my ($name, $url) = @_;

    $url =~ s/\|/%7C/g;

    ok($url =~ m{^https?://}, "$name '$url' should be a full URI line $.");

    ok($url !~ m{,}, "bare comma in $name $url line $.");

    my $uri = URI->new($url);
    is($uri, $url, "$name '$url' should be a valid URI line $.");

    return $uri;
}

sub load_whitelist {
    my $filename = shift;
    local *FILE;
    open(FILE, "< $filename") or die "unable to open whitelist $filename";
    while (<FILE>) {
        chomp;
        $_ =~ s/\s*\#.*$//;
        $whitelist{$_} = 1 if ($_);
    }
}
