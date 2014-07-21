package Imager::Bing::MapLayer::Role::Centroid;

use v5.10;

use Moose::Role;

use Const::Fast;

=head1 NAME

Imager::Bing::MapLayer::Role::Centroid - a centroid role

=cut

use version 0.77; our $VERSION = version->declare('v0.1.5');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=head1 ATTRIBUTES

=cut

const my $LONDON_LATITUDE  => 51.5171;
const my $LONDON_LONGITUDE => 0.1062;

=head2 C<centroid_latitude>

This is the default latitude for translating points to pixels.

This defaults to a latitude in London.

=cut

has 'centroid_latitude' => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { return $LONDON_LATITUDE },
);

=head2 C<centroid_longitude>

This is the default longitude for translating points to pixels.

This defaults to a longitude in London.

=cut

has 'centroid_longitude' => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { return $LONDON_LONGITUDE },
);

1;

