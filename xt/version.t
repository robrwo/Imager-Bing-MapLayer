use Test::More;

eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for checking versions"
    if $@;
Test::ConsistentVersion::check_consistent_versions();

