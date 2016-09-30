package Monorail::SQLTrans::Producer::PostgreSQL;

use base 'SQL::Translator::Producer::PostgreSQL';
use strict;
use warnings;

sub drop_view {
    my ($view, $options) = @_;

    my $generator = SQL::Translator::Producer::PostgreSQL::_generator($options);

    return sprintf('DROP VIEW %s', $generator->quote($view->name));
}

sub alter_view {
    my ($view, $options) = @_;

    my $sql = SQL::Translator::Producer::PostgreSQL::create_view($view, $options);

    $sql =~ s/^CREATE/CREATE OR REPLACE/m;

    return $sql;
}

sub create_procedure {
    my ($procedure, $options) = @_;

    return _create_function($procedure, { or_replace => 0}, $options);
}

sub alter_procedure {
    my ($procedure, $options) = @_;

    return _create_function($procedure, { or_replace => 1}, $options);
}

sub _create_function {
    my ($procedure, $args, $options) = @_;

    my $generator  = SQL::Translator::Producer::PostgreSQL::_generator($options);
    my $or_replace = $args->{or_replace} ? 'OR REPLACE ' : '';
    my $name       = $generator->quote($procedure->name);
    my $sql = sprintf('CREATE %sFUNCTION %s (%s) ',
        $or_replace, $name, join(', ' => map { $generator->quote($_) } $procedure->parameters)
    );

    my @definitions;
    if (my $returns = $procedure->extra('returns')) {
        $returns = $generator->quote($returns);
        push(@definitions, "RETURNS $returns");
    }

    if (my $lang = $procedure->extra('language')) {
        $lang = $generator->quote($lang);
        push(@definitions, "LANGUAGE $lang");
    }

    my $quote_delim    = '$__SQL_TRANS_SEP__$';
    my $implementation = $procedure->sql;
    push(@definitions, "AS $quote_delim\n$implementation\n$quote_delim");

    $sql .= join(' ', @definitions);

    return $sql;
}

sub drop_procedure {
    my ($procedure, $options) = @_;
    my $generator  = SQL::Translator::Producer::PostgreSQL::_generator($options);

    return sprintf('DROP FUNCTION %s (%s)',
        $generator->quote($procedure->name),
        join(', ' => map { $generator->quote($_) } $procedure->parameters)
    );
}


1;
