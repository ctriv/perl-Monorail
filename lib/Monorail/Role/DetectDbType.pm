package Monorail::Role::DetectDbType;

use Moose::Role;

#requires 'dbix';

has db_type => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_db_type',
);

my %sqlt_name_for = (
    Pg     => 'PostgreSQL',
    mysql  => 'MySQL',
    SQLite => 'SQLite',
    Oracle => 'Oracle',
    Sybase => 'Sybase',
);


sub _build_db_type {
    my ($self) = @_;

    my $dbh      = $self->dbix->storage->dbh;
    my $dbi_name = $dbh->{Driver}->{Name};

    return $sqlt_name_for{$dbi_name} || die "Unsupported Database Type: $dbi_name\n";
}


1;
__END__
