package Monorail::Role::Change;

use Moose::Role;
use Data::Dumper ();

requires qw/as_hashref_keys transform_database transform_model/;

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

    my $args_dump = Data::Dumper->new([$self->as_hashref])->Deparse(1)->Terse(1)->Indent(2)->Quotekeys(0)->Sortkeys($key_sorter)->Dump;
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



1;
__END__
