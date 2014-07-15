use strict;
use warnings;

use Test::More;
use Test::CleanNamespaces;

namespaces_clean(qw/
  Imager::Bing::MapLayer
  Imager::Bing::MapLayer::Level
  Imager::Bing::MapLayer::Tile
  Imager::Bing::MapLayer::Image
/);

done_testing;
