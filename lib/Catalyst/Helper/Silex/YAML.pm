package Catalyst::Helper::Silex::YAML;
# ABSTRACT: Silex helper to create catalyst application

use strict;
use warnings;
use File::Spec;

sub mk_stuff {
    my ($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $app  = lc $helper->{app};

    $app =~ s/::/_/g;

    my $path = File::Spec->catfile($base, "$app.yml");

    ( my $module_prefix = $helper->{app}    ) =~ s/::Web$//;
    ( my $db            = lc $module_prefix ) =~ s/::/_/g;

    my %vars = (
        MODULE_PREFIX => $module_prefix,
        DB            => $db,
    );
    $helper->render_file('yaml', $path, \%vars);
}

1;

=head1 SYNOPSIS

    > script/myapp_create.pl Silex::YAML

=head1 DESCRIPTION

This helper module is for Silex.

=head1 SEE ALSO

=over

=item *

L<Catalyst::Helper>

=back

=cut

__DATA__

__yaml__
name: [% app %];

"View::TT":
  DEFAULT_ENCODING: UTF-8
  ENCODING:         UTF-8

"Unicode::Encoding":
  encoding: UTF-8

"Model::API":
  class: [% MODULE_PREFIX %]::API
  args:
    [% DB %]:
      dsn: DBI:mysql:[% DB %]:127.0.0.1
      username: [% DB %]
      password: [% DB %]
      attributes:
        RaiseError:           1
        AutoCommit:           1
        mysql_enable_utf8:    1
        mysql_auto_reconnect: 1
        on_connect_do:
          - SET NAMES 'utf8'
          - SET CHARACTER SET 'utf8'
      cache_file: __HOME__/cache/[% DB %].cache

"Plugin::Authentication":
  default_realm: members
  realms:
    members:
      credential:
        class:          Password
        password_field: password
        password_type:  clear
      store:
        class:         Fey::ORM
        user_model:    [% MODULE_PREFIX %]::Model::User
        id_field:      username
        role_relation: roles
        role_field:    name
