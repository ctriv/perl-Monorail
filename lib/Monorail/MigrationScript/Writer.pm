package Monorail::MigrationScript::Writer;

use Moose;
use SQL::Translator::Diff;
use Text::MicroTemplate::DataSection qw(render_mt);
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

has diff => (
    is       => 'ro',
    isa      => 'SQL::Translator::Diff',
    required => 1,
);

has reversed_diff => (
    is       => 'ro',
    isa      => 'SQL::Translator::Diff',
    required => 1,
    lazy     => 1,
    builder  => '_build_reversed_diff',
);

has dependencies => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
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

    my $dependencies  = join('  ', @{$self->dependencies});
    my @upgrade_sql   = $self->diff->produce_diff_sql;
    my @downgrade_sql = $self->reversed_diff->produce_diff_sql;

    @upgrade_sql   = $self->_munge_sql(@upgrade_sql);
    @downgrade_sql = $self->_munge_sql(@downgrade_sql);

    my $perl = render_mt('migration_script', $dependencies, \@upgrade_sql, \@downgrade_sql);

    my $filename = sprintf("%s/%s.pl", $self->basedir, $self->name);

    make_path($self->basedir);

    open(my $fh, '>', $filename) || die "Couldn't open $filename: $!\n";
    print $fh $perl;
    close($fh) || die "Couldn't close $filename: $!\n";

    return 1;
}

sub _build_reversed_diff {
    my ($self) = @_;

    my $diff = $self->diff;

    return SQL::Translator::Diff->new({
        output_db     => $diff->output_db,
        source_schema => $diff->target_schema,
        target_schema => $diff->source_schema,
    })->compute_differences;
}

sub _munge_sql {
    my ($self, @rows) = @_;

    @rows = grep { m/\S/ && !m/^BEGIN/ && !m/^COMMIT/ && !m/^--/ }
             map { s/\s+$//; s/^\s+//; s/"/\\"/; $_ }
             @rows;

    return @rows;
}

1;
__DATA__

@@ migration_script
#!perl

use Moose;

with 'Monorail::Migration';

__PACKAGE__->meta->make_immutable;


sub dependencies {
    return [qw/<?= $_[0] ?>/];
}

sub upgrade_sql {
    return [
? foreach my $statement (@{$_[1]}) {
        "<?= $statement ?>",
? }
    ];
}

sub upgrade_extras {
    my ($self) = @_;
    # $self->dbix gives you access to your DBIx::Class schema if you need to add
    # data  do extra work, etc....
    #
    # For example:
    #
    #  $self->dbix->tnx_do(sub {
    #      $self->dbix->resultset('foo')->insert(%stuff)
    #  });
}

sub downgrade_sql {
    return [
? foreach my $statement (@{$_[2]}) {
        "<?= $statement ?>",
? }
    ];
}

sub downgrade_extras {
    my ($self) = @_;
    # Same drill as upgrade_extras - you know what to do!
}

1;
