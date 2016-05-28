package Monorail::MigrationScript::Writer;

use Moose;
use SQL::Translator::Diff;
use Text::MicroTemplate::DataSection qw(render_mt);
use Text::MicroTemplate qw(encoded_string);

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

    my $dependencies      = join('  ', @{$self->dependencies});
    my @upgrade_changes   = $self->diff->produce_diff_sql;

    # use Data::Dumper;
    # warn Dumper($self->reversed_diff);

    my @downgrade_changes = $self->reversed_diff->produce_diff_sql;

    @upgrade_changes   = $self->_munge_diff(@upgrade_changes);
    @downgrade_changes = $self->_munge_diff(@downgrade_changes);

    return 0 unless @upgrade_changes;

    my $perl = render_mt('migration_script', {
        depends    => encoded_string($dependencies),
        up_steps   => [map { encoded_string($_) } @upgrade_changes],
        down_steps => [map { encoded_string($_) } @downgrade_changes],
    });

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
        # ignore_missing_methods => 1,
    })->compute_differences;
}

sub _munge_diff {
    my ($self, @diff) = @_;

    @diff = grep { m/^Monorail::/ } @diff;
    for (@diff) {
        s/;\s+$//s;
        s/^/        /mg;
    }

    return @diff;
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
