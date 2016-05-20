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

requires qw/as_hashref_keys/;

# table first, then name, then the rest sorted alpha.
my $key_sorter = sub {
    return [
        sort {
            return -1 if $a eq 'table';
            return 1 if $b eq 'table';

            return -1 if $a eq 'name';
            return 1 if $b eq 'name';

            return $a cmp $b;
        } keys %{$_[0]}
    ]
};

sub as_perl {
    my ($self) = @_;

    my $args_dump = Data::Dumper->new([$self->as_hashref])->Terse(1)->Indent(2)->Quotekeys(0)->Sortkeys($key_sorter)->Dump;
    $args_dump    =~ s/^{|}\s*$//g;

    my $class = $self->meta->name;

    return sprintf("%s->new(%s)", $class, $args_dump);
}

sub as_hashref {
    my ($self) = @_;

    return {
        map { $_ => $self->$_ } $self->as_hashref_keys
    }
}


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

1;
__END__
