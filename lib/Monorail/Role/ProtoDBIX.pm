package Monorail::Role::ProtoDBIX;

use Moose::Role;

requires 'dbix';


has protodbix => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    lazy    => 1,
    builder => '_build_protodbix',
);


sub _build_protodbix {
    my ($self) = @_;

    return DBIx::Class::Schema->connect(sub { $self->dbix->storage->dbh });
}


1;
__END__
