package Monorail::Recorder;

use Moose;
use DBIx::Class::Schema;
use SQL::Translator;
use SQL::Translator::Diff;

our $TableName = 'monorail_deployed_migrations';

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has version_resultset => (
    is       => 'ro',
    isa      => 'DBIx::Class::ResultSet',
    lazy     => 1,
    builder  => '_build_version_resultset'
);

has version_resultset_name => (
    is      => 'ro',
    isa     => 'Str',
    default => '__monorail_migrations'
);

has protoschema => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    lazy    => 1,
    builder => '_build_protoschema',
);

has _table_is_present => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;


sub is_applied {
    my ($self, $name) = @_;

    $self->_ensure_our_table;

    if ($self->version_resultset->single({name => $name})) {
        return 1;
    }
    else {
        return;
    }
}

sub mark_as_applied {
    my ($self, $name) = @_;

    $self->_ensure_our_table;

    $self->version_resultset->create({
        name => $name
    });
}


sub _build_version_resultset {
    my ($self) = @_;

    return $self->protoschema->resultset($self->version_resultset_name);
}

sub _build_protoschema {
    my ($self) = @_;

    require Monorail::Recorder::monorail_resultset;

    my $schema = DBIx::Class::Schema->connect(sub { $self->dbix->storage->dbh });
    $schema->register_class($self->version_resultset_name => 'Monorail::Recorder::monorail_resultset');

    return $schema;
}

sub _ensure_our_table {
    my ($self) = @_;

    return if $self->_table_is_present;

    my $has_table = eval { $self->version_resultset->is_installed; 1 };

    if (!$has_table) {
        $self->protoschema->deploy;
    }

    $self->_table_is_present(1);
}

1;
__END__
