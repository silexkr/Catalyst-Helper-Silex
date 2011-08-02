package Catalyst::Helper::Silex::Fey::ORM;
# ABSTRACT: Silex helper to create catalyst application

use strict;
use warnings;

use App::mkfeyorm;
use Const::Fast;
use File::Basename;

sub mk_stuff {
    my ( $self, $helper ) = @_;

    ( my $module_prefix = $helper->{app} ) =~ s/::Web$//;

    const my $NAMESPACE       => $module_prefix;
    const my $SCHEMA          => 'Schema';
    const my $TABLE_NAMESPACE => 'Model';
    const my $USER_TABLE      => 'User';
    const my @TABLES => (qw/
        Role
        User
        UserRole
    /);

    my $app = App::mkfeyorm->new(
        namespace       => $NAMESPACE,
        schema          => $SCHEMA,
        table_namespace => $TABLE_NAMESPACE,
        tables          => [ @TABLES ],
        cache           => 1,
    );

    my $base = $helper->{base};

    #
    # Schema
    #
    {
        my $content;
        $app->process_schema(\$content);

        my $path = File::Spec->catfile(
            $base,
            'lib',
            $app->module_path($app->schema_module),
        );

        $helper->mk_dir( dirname($path) );
        $helper->mk_file( $path, $content );
    }

    #
    # Role, UserRole table
    #
    for my $table ( qw/ Role UserRole / ) {
        my $content;
        $app->process_table($table, $app->tables->{$table}, \$content);

        my $path = File::Spec->catfile(
            $base,
            'lib',
            ($app->module_path($app->table_modules($table)))[0],
        );

        $helper->mk_dir( dirname($path) );
        $helper->mk_file( $path, $content );
    }

    #
    # User table
    #
    {
        my $table = 'User';

        $app->set_template_params({
            USER        => $app->tables->{'User'},
            ROLE        => $app->tables->{'Role'},
            USER_ROLE   => $app->tables->{'UserRole'},
            ROLE_MODULE => ($app->table_modules('Role'))[0],
        });

        my $template = $helper->get_file( __PACKAGE__, 'fey' );
        $app->set_table_template( $template );

        my $content;
        $app->process_table($table, $app->tables->{$table}, \$content);

        my $path = File::Spec->catfile(
            $base,
            'lib',
            ($app->module_path($app->table_modules($table)))[0],
        );

        $helper->mk_dir( dirname($path) );
        $helper->mk_file( $path, $content );
    }
}

1;

=head1 SYNOPSIS

    > script/myapp_create.pl Silex::Fey::ORM

=head1 DESCRIPTION

This helper module is for Silex.

=head1 SEE ALSO

=over

=item *

L<App::mkfeyorm>

=back

=cut

__DATA__

__fey__
[% DEBUG on -%]
package [% TABLE %];
use Fey::ORM::Table;
use [% SCHEMA %];

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use namespace::autoclean;

has roles => (
    is         => 'ro',
    isa        => 'Fey::Object::Iterator::FromSelect',
    lazy_build => 1,
);

sub _build_roles {
    my $self = shift;

    my $schema    = [% SCHEMA %]->Schema;
    my $dbh       = [% SCHEMA %]->DBIManager->default_source->dbh;
    my $user      = $schema->table('[% PARAMS.USER %]');
    my $role      = $schema->table('[% PARAMS.ROLE %]');
    my $user_role = $schema->table('[% PARAMS.USER_ROLE %]');

    my $select = [% SCHEMA %]->SQLFactoryClass->new_select
        ->select($role)
        ->from($role,      $user_role)
        ->from($user_role, $user)
        ->where($user->column('id'), '=', Fey::Placeholder->new)
        ;

    return Fey::Object::Iterator::FromSelect->new(
        classes     => '[% PARAMS.ROLE_MODULE %]',
        dbh         => $dbh,
        select      => $select,
        bind_params => [ $self->id ],
    );
}

sub load {
    my $class = shift;

    return unless $class;
    return if     $class->Table;

    my $schema = [% SCHEMA %]->Schema;
    my $table  = $schema->table('[% DB_TABLE %]');

    has_table( $table );

    #
    # Add another relationships like has_one, has_many or etc.
    #
    #has_many items => ( table => $schema->table('item') );
}

1;
