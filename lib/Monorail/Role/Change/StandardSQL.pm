package Monorail::Role::Change::StandardSQL;

use Moose::Role;
use SQL::Translator;
#use Sub::Install qw(install_stub reinstall_stub);
#use namespace::autoclean;

with 'Monorail::Role::Change';

requires qw/as_sql/;

has producer => (
    is       => 'ro',
    isa      => 'Monorail::SQLTrans::ProducerProxy',
    lazy     => 1,
    builder  => '_build_producer',
);

# might break this into its own role that requires 'table'
has schema_table_object => (
    is      => 'ro',
    isa     => 'SQL::Translator::Schema::Table',
    lazy    => 1,
    builder => '_build_schema_table_object',
);


sub add_dbix_sqlt_callback {
    my ($self, $dbix, $source, $cb) = @_;

    my $source_class = $dbix->source($source)->result_class;

    my $existing = $source_class->can('sqlt_deploy_hook');

    my $new;
    if ($existing) {
        $new = sub {
            $existing->(@_);
            $cb->(@_);
        };
    }
    else {
        $new = $cb;
    }

    {
        no strict 'refs';
        no warnings 'redefine';

        *{"${source_class}::sqlt_deploy_hook"} = $new;
    }
}

sub _build_schema_table_object {
    my ($self) = @_;

    require SQL::Translator::Schema::Table;
    return SQL::Translator::Schema::Table->new(name => $self->table);
}

sub _build_producer {
    my ($self) = @_;

    require Monorail::SQLTrans::ProducerProxy;
    return  Monorail::SQLTrans::ProducerProxy->new(db_type => $self->db_type);
}

sub transform_database {
    my ($self, $schema) = @_;

    foreach my $statement ($self->as_sql) {
        $schema->storage->dbh->do($statement);
    }
}


1;
