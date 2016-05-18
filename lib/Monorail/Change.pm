package Monorail::Change;

use Moose::Role;
use Data::Dumper ();

has producer => (
    is       => 'ro',
    isa      => 'Monorail::SQLTrans::ProducerProxy',
    lazy     => 1,
    builder  => '_build_producer',
);

has db_type => (
    is  => 'rw',
    isa => 'Str',
);

# might break this into its own role that requires 'table'
has schema_table_object => (
    is      => 'ro',
    isa     => 'SQL::Translator::Schema::Table',
    lazy    => 1,
    builder => '_build_schema_table_object',
);

requires 'as_hashref_keys';


sub as_perl {
    my ($self) = @_;

    my $args_dump = Data::Dumper->new([$self->as_hashref])->Terse(1)->Indent(0)->Dump;
    $args_dump    =~ s/^{|}$//g;

    my $class = $self->meta->name;

    return sprintf("%s->new(%s)", $class, $args_dump);
}

sub as_hashref {
    my ($self) = @_;

    return {
        map { $_ => $self->$_ } $self->as_hashref_keys
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

1;
__END__
