package Monorail::MigrationScript;

use Moose;
use UUID::Tiny qw(:std);
use File::Slurper qw(read_text);
use Path::Class;
use namespace::autoclean;

has filename => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has inner_obj => (
    is      => 'ro',
    does    => 'Monorail::Migration',
    lazy    => 1,
    builder => '_build_inner_obj',
    handles => [qw/upgrade downgrade dependencies/],
);

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_name',
);


__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS


    my $migration = Monorail::MigrationScript->new(filename => $filename);

    say "Going to run " . $migration->name;

    $migration->upgade;

    # or

    $migration->downgrade

=cut

sub _build_inner_obj {
    my ($self) = @_;

    my $uuid = create_uuid_as_string();
    $uuid =~ s/-/_/g;

    my $classname = "migration_$uuid";

    my $perl = read_text($self->filename);
    $perl = "package $classname;\n$perl";

    eval "$perl";
    die $@ if $@;

    return $classname->new(dbix => $self->dbix);
}


sub _build_name {
    my ($self) = @_;

    my $name = file($self->filename)->basename;
    $name =~ s:\.pl$::;

    return $name;
}


1;
__END__
