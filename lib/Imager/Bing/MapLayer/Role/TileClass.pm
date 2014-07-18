package Imager::Bing::MapLayer::Role::TileClass;

use v5.10;

use feature qw/ state /;

use Moose::Role;

use Type::Tiny;
use Module::Load qw/ load /;

use version 0.77; our $VERSION = version->declare('v0.1.5');

state $Type = Type::Tiny->new(
    name       => 'TileClass',
    constraint => sub {
	my $class = $_;
	load $class;
	$class->isa('Imager::Bing::MapLayer::Tile');
    },
    message    => sub {
	"$_ must be a Imager::Bing::MapLayer::Tile";
    },
    );

=head2 C<tile_class>

The base class used for tiles.

=cut

has 'tile_class' => (
    is      => 'ro',
    isa     => $Type,
    default => sub { 'Imager::Bing::MapLayer::Tile' },
);


1;
