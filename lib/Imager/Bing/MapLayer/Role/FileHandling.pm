package Imager::Bing::MapLayer::Role::FileHandling;

use v5.10;

use Moose::Role;

use Cwd;

use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints;

use version 0.77; our $VERSION = version->declare('v0.1.5');

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

1;
