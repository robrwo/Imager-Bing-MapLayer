package Imager::Bing::MapLayer;

use v5.10.1;

use Moose;

use Carp qw/ confess /;
use Class::MOP::Method;
use Const::Fast;
use Cwd;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

use Imager::Bing::MapLayer::Utils qw/
    $MIN_ZOOM_LEVEL $MAX_ZOOM_LEVEL
    /;

use aliased 'Imager::Bing::MapLayer::Level';

=head1 NAME

Imager::Bing::MapLayer - create a map layer for Bing Maps

=head1 VERSION

Version v0.1.0

=cut

use version 0.77; our $VERSION = version->declare('v0.1.0');

=head1 SYNOPSIS

    my $layer = Imager::Bing::MapLayer->new(
      base_dir           => $dir,     # base directory (default '.')
      overwrite          => 1,        # overwrite existing (default)
      autosave           => 1,        # save on exit (default)
      in_memory          => 0,        # keep tiles in memory (default false)
      min_level          => 1,        # min zoom level (default)
      max_level          => 19,       # max zoom level (default)
      combine            => 'darken', # tile composition method (default)
    );

    # Plot polygons (e.g. geographic boundaries)

    $layer->polygon(
       points => $points,                  # listref to [ lat, lon ] points
       fill   => Imager::Fill->new( ... ), #
    );

    # Plot greyscale gradient circles for heatmaps

    $layer->radial_circle(
        r      => 100,              # radius in meters
        -min_r => 1,                # minimum pixel radius for any zoom level
        x      => $longitude,       # longitude (x = east-west)
        y      => $latitude,        # latitude  (y = north-south)
    );

    # Blur filter

    $layer->filter( type => 'gaussian', stddev => 1 );

    # Colourise greyscale heatmaps

    $layer->colourise();

=head1 DESCRIPTION

This module is a wrapper around the L<Imager::Draw> module, which
allows you to create Bing map layers using longitude and latitude
coordinates.

The module will automatically map them to the appropriate points on
tile files.

=head1 ATTRIBUTES

=cut

# We want to center our conversions of lat/lon to London.

const my $LONDON_LATITUDE  => 51.5171;
const my $LONDON_LONGITUDE => 0.1062;

=head2 C<base_dir>

The base directory to save tile files in.

=cut

has 'base_dir' => (
    is  => 'ro',
    isa => subtype( as 'Str', where { -d $_ }, ),
    default => sub { return getcwd; },
);

=head2 C<in_memory>

The timeout for how many seconds a tile is kept in memory.

When a tile is timed out, it is saved to disk after each L<Imager> drawing
operation, and reloaded if it is later needed.

=cut

has 'in_memory' => (
    is  => 'ro',
    isa => subtype( as 'Int', where { ( $_ >= 0 ) }, ),
    default => sub { return 0; },
);

=head2 C<centroid_latitude>

This is the default latitude for translating points to pixels.
Generally you don't need to worry about this.

=cut

has 'centroid_latitude' => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { return $LONDON_LATITUDE },
);

=head2 C<centroid_longitude>

This is the default longitude for translating points to pixels.
Generally you don't need to worry about this.

=cut

has 'centroid_longitude' => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { return $LONDON_LONGITUDE },
);

=head2 C<overwrite>

When true (default), existing tiles will be overwritten rather than
edited.

Be wary of editing existing tiles, since antialiased lines and opaque
fills will darken existing points rather than drawing over them.

=cut

has 'overwrite' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { return 1; },
);

=head2 C<autosave>

When true (default), tiles will be automatically saved.

Alternatively, you can use the L</save> method.

=cut

has 'autosave' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { return 1; },
);

=head2 C<combine>

The tile combination method. It defaults to C<darken>.

=cut

has 'combine' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { return 'darken'; },
);

=head1 METHODS

=head2 C<levels>

  my @levels = @{ $layer->levels };

This returns a reference to a list of
L<Imager::Bing::MapLayer::Level> objects.

=cut

has 'levels' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        confess "min_level > max_level"
            if ( $self->min_level > $self->max_level );

        my @levels;

        foreach my $level ( $self->min_level .. $self->max_level ) {
            push @levels,
                Level->new(
                level              => $level,
                base_dir           => $self->base_dir,
                centroid_latitude  => $self->centroid_latitude,
                centroid_longitude => $self->centroid_longitude,
                overwrite          => $self->overwrite,
                autosave           => $self->autosave,
                in_memory          => $self->in_memory,
                combine            => $self->combine,
                );
        }

        return \@levels;
    },
);

=head2 C<min_level>

The minimum zoom level to generate.

=cut

has 'min_level' => (
    is  => 'ro',
    isa => subtype(
        as 'Int',
        where { ( $_ >= $MIN_ZOOM_LEVEL ) && ( $_ <= $MAX_ZOOM_LEVEL ) }
    ),
    default => sub {$MIN_ZOOM_LEVEL},
);

=head2 C<max_level>

The maximum zoom level to generate.

=cut

has 'max_level' => (
    is  => 'ro',
    isa => subtype(
        as 'Int',
        where { ( $_ >= $MIN_ZOOM_LEVEL ) && ( $_ <= $MAX_ZOOM_LEVEL ) }
    ),
    default => sub {$MAX_ZOOM_LEVEL},
);

=begin internal

=head2 C<_make_imager_wrapper_method>

    __PACKAGE__->_make_imager_wrapper_method( { name => $method } );

This is an I<internal> method for generating wrapper L<Imagers::Draw>
methods that are applied to every level.

These methods use latitude and longitude in lieau of C<y> and C<x>
parameters.  Note that C<points> parameters contain pairs of latitude
and longitude coordinates, I<not> longitude and latitude coordinates!

See L<Imager::Draw> for documentation of the methods.

We've added the following additional arguments:

=over

=item C<-min_level>

The minimum zoom level to draw on.

=item C<-max_level>

The maximum zoom level to draw on.

=back

=end internal

=cut

sub _make_imager_wrapper_method {
    my ( $class, $opts ) = @_;

    $opts->{args} //= [];

    $class->meta->add_method(

        $opts->{name} => sub {

            my ( $self, %args ) = @_;

            foreach my $level ( @{ $self->levels } ) {

                my $method = $level->can( $opts->{name} );

                $level->$method(%args);

            }

            }

    );
}

=head2 C<radial_circle>

    $layer->radial_circle(
        r      => $radius_in_meters,
        -min_r => $min_radius_in_pixels,
        x      => $longitude,
        y      => $latitude,
    );

This method plots "fuzzy" greyscale circles, which are intended to be
used for heatmaps.  The radius is scaled appropriately for each zoom
level in the layer.

If C<-min_r> is specified, then a circle will always be drawn with
that minimum radius: this ensures that lower zoom levels will always
have a point plotted.

=head2 C<colourise>

    $layer->colourise();

The method colourises greyscale layers.  It is intended to be used for
heatmaps generated using the L</radial_circle> method.

=head2 C<filter>

    $layer->filter( type => 'gaussian', stddev => 1 );

This applies L<Imager::Filters> to every tile on every zoom level of the layer.

Be aware that some filter effects may enhance the edges of tiles in
each zoom level.

=head2 C<setpixel>

Draw a pixel at a specific latitude and longitude coordinate.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<line>

Draw a line between two coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<box>

Draw a box bounded by northwest and southeast coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<polyline>

Draw a polyline for a set of coordinates.

Note that a polyline is not closed. To draw a closed area, use the
L</polygon> method.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<polygon>

Draw a closed polygon for a set of coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<arc>

Draw an arc.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<circle>

Draw a circle.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<string>

Draw a text string.

TODO - the size is not scaled.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<align_string>

Draw an aligned text string.

TODO - the size is not scaled.

See the corresponding method in L<Imager::Draw> for more information.

=cut

foreach my $method (
    qw/
    radial_circle colourise
    filter setpixel line box polyline polygon arc circle flood_fill
    string align_string
    /
    )
{

    __PACKAGE__->_make_imager_wrapper_method( { name => $method } );

}

=head2 C<save>

Save the tiles.

=cut

sub save {
    my ( $self, @args ) = @_;

    foreach my $level ( @{ $self->levels } ) {
        $level->save(@args);
    }
}

=head1 KNOWN ISSUES

For plotting very large polylines and polygons, the system will die
with no error message.

See the F<TODO> file for other known issues and unimplemented features.

=head1 SEE ALSO

=over

* Bing Maps Tile System

L<http://msdn.microsoft.com/en-us/library/bb259689.aspx>

=back

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the author, or through
the web interface at
L<https://github.com/robrwo/Imager-Bing-MapLayer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Imager::Bing::MapLayer

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/robrwo/Imager-Bing-MapLayer>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item *

Foxtons, Ltd.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Robert Rothenberg.

This program is released under the following license: atistic2

=cut

use namespace::autoclean;

1;    # End of Imager::Bing::MapLayer
