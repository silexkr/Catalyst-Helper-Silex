package Catalyst::Helper::Silex::PSGI;
# ABSTRACT: Silex helper to create catalyst application

use strict;
use warnings;
use File::Spec;

sub mk_stuff {
    my ($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $app  = lc $helper->{app};

    $app =~ s/::/_/g;

    my $path = File::Spec->catfile($base, 'script', "$app.psgi");

    $helper->render_file('psgi', $path);
    chmod 0755, $path;
}

1;

=head1 SYNOPSIS

    > script/myapp_create.pl Silex::PSGI

=head1 DESCRIPTION

This helper module is for Silex.

=head1 SEE ALSO

=over

=item *

L<Catalyst::Helper>

=item *

L<Catalyst::Helper::PSGI>

=back

=cut

__DATA__

__psgi__
#!/usr/bin/env perl
use strict;
use warnings;
use [% app %];

[% app %]->setup_engine('PSGI');
my $app = sub { [% app %]->run(@_) };

use Plack::Builder;

builder {
    enable_if {
        $_[0]->{REMOTE_ADDR} eq '127.0.0.1'
    } "Plack::Middleware::ReverseProxy";

    $app;
};
