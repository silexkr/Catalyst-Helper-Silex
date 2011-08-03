package Catalyst::Helper::Silex;
# ABSTRACT: Silex helper to create catalyst application

use strict;
use warnings;
use File::Spec;

1;

=head1 SYNOPSIS

    > script/myapp_create.pl Silex::Fey::ORM
    > script/myapp_create.pl Silex::PSGI
    > script/myapp_create.pl Silex::YAML
    > script/myapp_create.pl Silex::API

and also available ARGS for implementation files

    > script/myapp_create.pl Silex::API Foo Bar Baz

=head1 DESCRIPTION

This helper module is for Silex.

=head1 SEE ALSO

=over

=item *

L<Catalyst::Helper>

=back

=cut
