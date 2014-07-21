package Imager::Bing::MapLayer::Role::TileClass;

use v5.10;

use feature qw/ state /;

use Moose::Role;

use Type::Tiny;
use Module::Load qw/ load /;

=head1 NAME

Imager::Bing::MapLayer::Role::TileClass - a tile class role

=cut

use version 0.77; our $VERSION = version->declare('v0.1.5');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=head1 ATTRIBUTES

=head2 C<tile_class>

The base class used for tiles.

=cut

state $Type = Type::Tiny->new(
    name       => 'TileClass',
    constraint => sub {
        my $class = $_;
        load $class;
        $class->isa('Imager::Bing::MapLayer::Tile');
    },
    message => sub {
        "$_ must be a Imager::Bing::MapLayer::Tile";
    },
);

has 'tile_class' => (
    is      => 'ro',
    isa     => $Type,
    default => sub {'Imager::Bing::MapLayer::Tile'},
);

1;
