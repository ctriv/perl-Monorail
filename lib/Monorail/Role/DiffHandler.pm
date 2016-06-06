package Monorail::Role::DiffHandler;

use Moose::Role;
use SQL::Translator::Diff;
use Clone qw(clone);

has source_schema => (
    is       => 'ro',
    isa      => 'SQL::Translator::Schema',
    required => 1,
);

has target_schema => (
    is       => 'ro',
    isa      => 'SQL::Translator::Schema',
    required => 1,
);

has forward_diff => (
    is      => 'ro',
    isa     => 'SQL::Translator::Diff',
    lazy    => 1,
    builder => '_build_forward_diff'
);

has reversed_diff => (
    is      => 'ro',
    isa     => 'SQL::Translator::Diff',
    lazy    => 1,
    builder => '_build_reversed_diff'
);

has output_db => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Monorail',
);


sub _build_forward_diff {
    my ($self) = @_;

    return SQL::Translator::Diff->new({
        output_db              => $self->output_db,
        source_schema          => clone($self->source_schema),
        target_schema          => clone($self->target_schema),
    })->compute_differences;
}

sub _build_reversed_diff {
    my ($self) = @_;

    my $src = clone($self->source_schema);
    my $tar = clone($self->target_schema);

    $self->_add_reversed_rename_mappings($src, $tar);

    return SQL::Translator::Diff->new({
        output_db     => $self->output_db,
        # note these are reversed
        source_schema => $tar,
        target_schema => $src,
    })->compute_differences;
}


sub _add_reversed_rename_mappings {
    my ($self, $from, $to) = @_;

    foreach my $table ($to->get_tables) {
        if (my $old_name = $table->extra('renamed_from')) {
            my $old_table = $from->get_table($old_name);
            $old_table->extra(renamed_from => $table->name);

            foreach my $field ($table->get_fields) {
                if (my $old_field_name = $field->extra('renamed_from')) {
                    my $old_field = $old_table->get_field($old_field_name);
                    $old_field->extra(renamed_from => $field->name);
                }
            }

        }
    }

    #use Data::Dumper;
    #die Dumper([$from, $to]);
}

1;
__END__
