package Monorail::MigrationScript::Set;

use Moose;
use Path::Class;
use namespace::autoclean;
use Monorail::MigrationScript;
use Algorithm::TSort qw(:all);

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has files => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_filelist'
);

has migrations => (
    is      => 'ro',
    isa     => 'ArrayRef[Monorail::MigrationScript]',
    lazy    => 1,
    builder => '_build_migrations'
);

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);


__PACKAGE__->meta->make_immutable;

sub in_topological_order {
    my ($self) = @_;

    my %adj;
    my %by_name;
    foreach my $migration (@{$self->migrations}) {
        $adj{$migration->name}     = $migration->dependencies;
        $by_name{$migration->name} = $migration;
    }

    my @sorted = reverse tsort(Graph(ADJ => \%adj), keys %adj);

    return map { $by_name{$_} } @sorted;
}


sub _build_filelist {
    my ($self) = @_;

    my $dir = dir($self->basedir);

    my @scripts;
    while (my $file = $dir->next) {
        next unless -f $file;
        push(@scripts, $file->stringify);
    }

    return \@scripts;
}

sub _build_migrations {
    my ($self) = @_;

    return [
        map {
            Monorail::MigrationScript->new(
                filename => $_,
                dbix     => $self->dbix,
            )
        } @{$self->files}
    ];
}

1;
__END__
