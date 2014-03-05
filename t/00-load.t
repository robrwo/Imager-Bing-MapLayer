#!perl -T
use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Imager::Bing::MapLayer' ) || print "Bail out!\n";
}

diag( "Testing Imager::Bing::MapLayer $Imager::Bing::MapLayer::VERSION, Perl $], $^X" );
