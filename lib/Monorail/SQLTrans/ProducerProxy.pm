package Monorail::SQLTrans::ProducerProxy;

use Moose;
use Module::Runtime qw(require_module);
use namespace::autoclean;

has db_type => (
    is      => 'ro',
    isa     => 'Str',
    default => 'PostgreSQL'
);

has producer_class => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_producer_class',
);


sub _build_producer_class {
    my ($self) = @_;

    my $class = 'SQL::Translator::Producer::' . $self->db_type;

    require_module($class);

    return $class;
}


foreach my $meth (qw/add_field create_table drop_field drop_table/) {
    __PACKAGE__->meta->add_method(
        $meth => sub {
            my $self = shift;
            my $implementation = $self->producer_class->can($meth);
            return $implementation->(@_);
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
