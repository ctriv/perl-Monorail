package Monorail::MigrationScript::Writer;

use Moose;
use SQL::Translator::Diff;
use Text::MicroTemplate::DataSection qw(render_mt);
use Text::MicroTemplate qw(encoded_string);
use Clone qw(clone);
use File::Path qw(make_path);

use namespace::autoclean;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has dependencies => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has filename => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_filename'
);

has out_filehandle => (
    is      => 'ro',
    isa     => 'FileHandle',
    lazy    => 1,
    builder => '_build_out_filehandle',
);

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

has upgrade_changes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_upgrade_changes',
);

has downgrade_changes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_downgrade_changes',
);

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    my $script = Monorail::MigrationScript::Writer->new(
        name    => $name,
        basedir => $self->basedir,
        diff    => $diff
    );

    $script->write_file;


=cut


sub write_file {
    my ($self) = @_;

    my $dependencies    = join('  ', @{$self->dependencies});
    my $upgrade_changes = $self->upgrade_changes;

    return 0 unless @$upgrade_changes;

    my $downgrade_changes = $self->downgrade_changes;

    my $perl = render_mt('migration_script', {
        depends    => encoded_string($dependencies),
        up_steps   => [map { encoded_string($_) } @$upgrade_changes],
        down_steps => [map { encoded_string($_) } @$downgrade_changes],
    });

    my $filename = $self->filename;
    my $fh       = $self->out_filehandle;

    print $fh $perl;
    close($fh) || die "Couldn't close $filename: $!\n";

    return 1;
}

sub _build_upgrade_changes {
    my ($self) = @_;

    my @changes = $self->forward_diff->produce_diff_sql;
    @changes    = $self->_munge_changes_strings(@changes);

    return \@changes;
}

sub _build_downgrade_changes {
    my ($self) = @_;

    #use Data::Dumper;
    #die Dumper($self->reversed_diff);

    my @changes = $self->reversed_diff->produce_diff_sql;
    @changes    = $self->_munge_changes_strings(@changes);

    return \@changes;
}

sub _build_filename {
    my ($self) = @_;

    return sprintf("%s/%s.pl", $self->basedir, $self->name);
}

sub _build_out_filehandle {
    my ($self) = @_;

    my $filename = $self->filename;

    make_path($self->basedir);

    open(my $fh, '>', $filename) || die "Couldn't open $filename: $!\n";

    return $fh;
}



sub _munge_changes_strings {
    my ($self, @changes) = @_;

    @changes = grep { m/^Monorail::/ } @changes;
    for (@changes) {
        s/;\s+$//s;
        s/^/        /mg;
    }

    return @changes;
}



sub _build_forward_diff {
    my ($self) = @_;

    my $src = clone($self->source_schema);
    my $tar = clone($self->target_schema);

    $self->_strip_irrelevent_rename_mappings($src, $tar);

    return SQL::Translator::Diff->new({
        output_db              => $self->output_db,
        source_schema          => $src,
        target_schema          => $tar,
    })->compute_differences;
}

sub _build_reversed_diff {
    my ($self) = @_;

    my $src = clone($self->source_schema);
    my $tar = clone($self->target_schema);

    $self->_strip_irrelevent_rename_mappings($src, $tar);
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
}

{
    my $do_strip = sub {
        my ($from, $to) = @_;

        my %to_tables = map { $_->name => $_ } $to->get_tables;

        foreach my $table ($from->get_tables) {
            if (my $old_name = $table->extra('renamed_from')) {
                if (!$to_tables{$old_name}) {
                    $table->remove_extra('renamed_from');
                }
            }

            foreach my $field ($table->get_fields) {
                my $renamed_from = $field->extra('renamed_from');

                next unless $renamed_from;

                my $other_table = $to_tables{$table->extra('renamed_from') || $table->name};
                if (!$other_table->get_field($renamed_from)) {
                    $field->remove_extra('renamed_from');
                }
            }
        }
    };

    sub _strip_irrelevent_rename_mappings {
        my ($self, $from_schema, $to_schema) = @_;

        $do_strip->($from_schema, $to_schema);
        $do_strip->($to_schema,   $from_schema);
    }
}

1;
__DATA__

@@ migration_script
#!perl
? local $_ = $_[0];

use Moose;

with 'Monorail::Role::Migration';

__PACKAGE__->meta->make_immutable;


sub dependencies {
    return [qw/<?= $_->{depends} ?>/];
}

sub upgrade_steps {
    return [
? foreach my $change (@{$_->{up_steps}}) {
<?= $change ?>,
? }
        # Monorail::Change::RunPerl->new(function => \&upgrade_extras),
    ];
}

sub upgrade_extras {
    my ($dbix) = @_;
    # $dbix gives you access to your DBIx::Class schema if you need to add
    # data do extra work, etc....
    #
    # For example:
    #
    #  $self->dbix->tnx_do(sub {
    #      $self->dbix->resultset('foo')->create(\%stuff)
    #  });
}

sub downgrade_steps {
    return [
? foreach my $change (@{$_->{down_steps}}) {
<?= $change ?>,
? }
        # Monorail::Change::RunPerl->new(function => \&downgrade_extras),
    ];
}

sub downgrade_extras {
    my ($dbix) = @_;
    # Same drill as upgrade_extras - you know what to do!
}

1;
