package Imager::Bing::MapLayer::Role::Misc;

use v5.10;

use Moose::Role;

use Moose::Util::TypeConstraints;

=head1 NAME

Imager::Bing::MapLayer::Role::Misc - misc shared attributions

=cut

use version 0.77; our $VERSION = version->declare('v0.1.5');

=head1 DESCRIPTION

This role is for internal use by L<Imager::Bing::MapLayer>.

=head1 ATTRIBUTES

=head2 C<combine>

The tile combination method. It defaults to C<darken>.

=cut

has 'combine' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { return 'darken'; },
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

1;
