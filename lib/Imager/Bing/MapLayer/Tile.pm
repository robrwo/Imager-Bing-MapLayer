package Imager::Bing::MapLayer::Tile;

use Moose;
use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints;

extends 'Imager::Bing::MapLayer::Image';

use Carp qw/ carp confess /;
use Class::MOP::Method;
use Cwd;
use Imager;
use List::Util 1.30 qw/ pairmap /;
use Path::Class qw/ file /;

use Imager::Bing::MapLayer::Utils qw/
    $MIN_ZOOM_LEVEL $MAX_ZOOM_LEVEL
    $TILE_WIDTH $TILE_HEIGHT
    width_at_level
    pixel_to_tile_coords tile_coords_to_pixel_origin
    tile_coords_to_quad_key quad_key_to_tile_coords
    /;

use version 0.77; our $VERSION = version->declare('v0.1.4');

=head1 SYNOPSIS

   my $tile = Imager::Bing::MapLayer::Tile->new(
       quad_key  => $key,       # the "quad key" for the tile
       base_dir  => $base_dir,  # the base directory for tiles (defaults to cwd)
       overwrite => 1,          # overwrite existing tile (default) vs load it
       autosave  => 1,          # automatically save tile when done (default)
    );

=head1 ATTRIBUTES

=head2 C<quad_key>

The quadrant key of the tile.

=cut

has 'quad_key' => (
    is  => 'ro',
    isa => subtype(
        as 'Str', where {qr/^[0-3]{$MIN_ZOOM_LEVEL,$MAX_ZOOM_LEVEL}$/},
    ),
    required => 1,
);

=head2 C<base_dir>

The base directory that tiles are saved in.

=cut

has 'base_dir' => (
    is  => 'ro',
    isa => subtype( as 'Str', where { -d $_ }, ),
    default => sub { return getcwd; },
);

=head2 C<overwrite>

If true (default), overwrite existing tile files.

Note that re-running a process to generate a tole on an existing file
is not an idemportent operation: opaque overlays and anti-aliasing
will darken a region instead of recreating a set image.

=cut

has 'overwrite' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { return 1; },
);

=head2 C<autosave>

If true (default), automatically save the tiles when the object is
destroyed.

=cut

has 'autosave' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { return 1; },
);

=head1 METHODS

=head2 C<level>

The zoom level for this tile.  It is determined by the L</quad_key>.

=cut

# Yes, some of the methods below are written as attributes rather.
# But as attributes, the values are cached.  Don't use them as an
# attribute!

has 'level' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        return length( $self->quad_key );
    },
    lazy => 1,
);

=head2 C<tile_coords>

The tile coordinates of this tile. They are determined by the
L</quad_key>.

=cut

has 'tile_coords' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my ($self) = @_;
        return [ ( quad_key_to_tile_coords( $self->quad_key ) )[ 0, 1 ] ],;
    },
    lazy => 1,
);

=head2 C<pixel_origin>

The coordinates of the top-left point on the tile. They are determined
by the L</quad_key>.

=cut

has 'pixel_origin' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my ($self) = @_;
        my $tile_coords = $self->tile_coords;
        return [ tile_coords_to_pixel_origin( @{$tile_coords} ) ],;
    },
    lazy => 1,
);

=head2 C<width>

The width of the tile.

=cut

has 'width' => (
    is  => 'ro',
    isa => subtype( as 'Int', where { $_ == $TILE_WIDTH }, ),
    default => sub { return $TILE_WIDTH },
    lazy    => 1,
);

=head2 C<height>

The height of the tile.

=cut

has 'height' => (
    is  => 'ro',
    isa => subtype( as 'Int', where { $_ == $TILE_HEIGHT }, ),
    default => sub { return $TILE_HEIGHT },
    lazy    => 1,
);

=head2 C<image>

The L<Imager> object.

=cut

has 'image' => (
    is      => 'ro',
    isa     => 'Imager',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        my $image = Imager->new(
            xsize    => $self->width,
            ysize    => $self->height,
            channels => 4,
        );

        my $file = $self->filename;

        if ( -e $file ) {

            if ( $self->overwrite ) {

                unlink $file
                    or carp
                    sprintf( "Could not remove file '%s': %s", $file, $! );

            } else {

                $image->read( file => $file )
                    or confess sprintf( "Cannot read file '%s': %s",
                    $file, $image->errstr );

            }

        }

        return $image;
    },
);

=head2 C<filename>

The full pathname of the tile, when saved.

=cut

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return file( $self->base_dir, $self->quad_key . '.png' )->stringify;
    },
);

=head2 C<latlon_to_pixel>

Translate latitude and longitude to a pixel on this zoom level.

=cut

sub latlon_to_pixel {
    my ( $self, @latlon ) = @_;
    return Imager::Bing::MapLayer::Utils::latlon_to_pixel( $self->level,
        @latlon );
}

=head2 C<latlons_to_pixels>

Translate a list reference of latitude and longitude coordinates to
pixels on this zoom level.

=cut

sub latlons_to_pixels {
    my ( $self, $latlons ) = @_;
    return [ map { [ $self->latlon_to_pixel( @{$_} ) ] } @{$latlons} ];
}

=head2 C<save>

Save this tile.

=cut

sub save {
    my ($self) = @_;

    # Only save an image if there's something on it

    if ( $self->image->getcolorusage ) {
        $self->image->write( file => $self->filename );
    }
}

=head2 C<DEMOLISH>

This method auto-saves the tile, if L</autosave> is enabled.

=cut

sub DEMOLISH {
    my ($self) = @_;
    $self->save if ( $self->autosave );
}

use namespace::autoclean;

1;
