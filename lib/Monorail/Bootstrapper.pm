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

has dbix_schema_dsn => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has out_filehandle => (
    is      => 'ro',
    isa     => 'FileHandle',
    lazy    => 1,
    builder => '_build_out_filehandle',
);

has lib_dirs => (
    is  => 'ro',
    isa => 'ArrayRef[Str]'
);

has perl => (
    is      => 'ro',
    isa     => 'Str',
    default => $Config{perlpath},
);

sub write_script_file {
    my ($self) = @_;

    my %template_args = map { $_ => encoded_string($self->$_) } qw/
        dbix_schema_class dbix_schema_connect_method dbix_schema_dsn
        scriptname basedir perl
    /;

    if ($self->lib_dirs) {
        $template_args{lib_dirs} = encoded_string(
            join(' ', @{$template_args{lib_dirs}})
        );
    }

    my $perl = render_mt('main_script', \%template_args);

    my $fh = $self->out_filehandle;
    print $fh $perl;
    close($fh) || die sprintf("Couldn't close %s: %s\n", $self->scriptname, $!);
}


sub _build_out_filehandle {
    my ($self) = @_;

    my $filename = $self->scriptname;

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

? if ($_->{lib_dirs}) {
use lib qw/<?= $_->{lib_dirs} ?>/;
? }

use Monorail;
use <?= $_->{dbix_schema_class} ?>;

my %valid_actions = map { $_ => 1 } qw/
    migrate make_migration sqlmigrate showmigrations showmigrationplan
/;

my $action = shift || usage();

unless ($valid_actions{$action}) {
    usage();
}

my $monorail = Monorail->new(
    basedir => '<?= $_->{basedir} ?>',
    dbix    => <?= $_->{dbix_schema_class} ?>-><?= $_->{dbix_schema_connect_method} ?>('<?= $_->{dbix_schema_dsn} ?>'),
);

$monorail->$action();

sub usage {
    die "Usage <?= $_->{scriptname} ?>: <" . join('|', sort keys %valid_actions)  . ">\n";
}
