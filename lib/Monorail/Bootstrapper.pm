package Monorail::Bootstrapper;

use Moose;
use Config;
use Text::MicroTemplate::DataSection qw(render_mt);
use Text::MicroTemplate qw(encoded_string);
use namespace::autoclean;

has basedir => (
    is      => 'ro',
    isa     => 'Str',
    default => 'migrations'
);

has scriptname => (
    is      => 'ro',
    isa     => 'Str',
    default => 'monorail.pl'
);

has dbix_schema_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has dbix_schema_connect_method => (
    is      => 'ro',
    isa     => 'Str',
    default => 'connect',
);

has out_filehandle => (
    is      => 'ro',
    isa     => 'FileHandle',
    lazy    => 1,
    builder => '_build_out_filehandle',
);

sub write_script_file {
    my ($self) = @_;

    my $perl = render_mt('main_script', {
        dbix_schema_class          => encoded_string($self->dbix_schema_class),
        dbix_schema_connect_method => encoded_string($self->dbix_schema_connect_method),
        scriptname                 => encoded_string($self->scriptname),
        basedir                    => encoded_string($self->basedir),
    });

    my $fh = $self->out_filehandle;
    print $fh $perl;
    close($fh) || die sprintf("Couldn't close %s: %s\n", $self->scriptname, $!);
}


sub _build_out_filehandle {
    my ($self) = @_;

    my $filename = $self->scriptname;

    make_path($self->basedir);

    open(my $fh, '>', $filename) || die "Couldn't open $filename: $!\n";

    return $fh;
}

__PACKAGE__->meta->make_immutable;

1;

__DATA__

@@ main_script
? local $_ = $_[0];
#!<?= $_->{perl} ?>

use strict;
use warnings;
use Monorail;
use lib '<?= $_->{dbix_schema_class} ?>';

my %valid_actions = map { $_ => 1 } qw/
    migrate make_migration sqlmigrate showmigrations showmigrationplan
/;

my $action = shift || usage();

unless ($valid_actions{$action}) {
    usage();
}

my $monorail = Monorail->new(
    basedir => '<?= $_->{basedir} ?>',
    dbix    => <?= $_->{dbix_schema_class} ?>-><?= $_->{dbix_schema_connect_method} ?>,
);

$monorail->$action();

sub usage {
    die "Usage <?= $_->{scriptname} ?>: <" . join('|', sort keys %valid_actions)  . ">\n";
}
