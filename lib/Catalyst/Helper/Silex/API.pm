package Catalyst::Helper::Silex::API;
# ABSTRACT: Silex helper to create skeletons of API, Model, Traits and newer configuration

use strict;
use warnings;
use File::Spec;

=head2 mk_stuff

this method works like a main function.
if user typed like below..

    $ script/create.pl API Foo Bar Baz

L<Catalyst::Helper> will invoke this method with 'qw/Foo Bar Baz/' args

=cut

sub mk_stuff {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};     # current directory
    my $app = $helper->{app};       # ex) Foo::Web
    $app =~ s/::(:?www$|web$)//i;

    my $schema = sprintf "%s/%s/%s", 'lib', $app, 'Schema';
    die qq{$schema/ and $schema.pm files are required.\nCan't locate $schema.pm or $schema/} unless -d $schema or -e "$schema.pm";

    $helper->{var} = {
        ns      => $app,            # 'ns' is a shortname of 'NameSpace'
        app     => $helper->{app},
        apis    => \@args || [],
    };

    $self->$_($helper, @args) for (qw/mk_traits mk_model mk_api mk_conf/);
}

sub mk_traits {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $path = sprintf "%s/%s/%s", 'lib', $helper->{var}{ns}, 'Trait';
    $path =~ s/::/\//g;

    $helper->mk_dir(File::Spec->catfile($base, $path));     # lib/Foo/Trait
    $helper->mk_dir(File::Spec->catfile($base, 'conf'));    # conf
    $helper->mk_dir(File::Spec->catfile($base, 'logs'));    # logs

    for my $trait (qw/trait_WithAPI trait_WithDBIC trait_Log/) {
        my $to = $trait;
        $to =~ s/^trait_//;
        $to .= '.pm';
        my $pm = File::Spec->catfile($base, $path, $to);
        $pm .= '.new' if -e $pm;
        $helper->render_file($trait, $pm, $helper->{var});
    }

    my $conf = File::Spec->catfile($base, "conf", 'log4perl.conf');
    $conf .= '.new' if -e $conf;
    $helper->render_file('log4perl', $conf, $helper->{var});
}

sub mk_model {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $path = sprintf "%s/%s/%s", 'lib', $helper->{app}, 'Model';
    $path =~ s/::/\//g;

    $helper->mk_dir(File::Spec->catfile($base, $path));
    my $pm = File::Spec->catfile($base, $path, 'API.pm');
    $pm .= '.new' if -e $pm;
    $helper->render_file('model_api', $pm, $helper->{var});
}

sub mk_api {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $path = sprintf "%s/%s", 'lib', $helper->{var}{ns};
    $path =~ s/::/\//g;

    $helper->mk_dir(File::Spec->catfile($base, $path, 'API'));  # lib/Foo/API

    my $pm = File::Spec->catfile($base, $path, 'API.pm');
    $pm .= '.new' if -e $pm;
    $helper->render_file('api', $pm, $helper->{var});

    for my $api (@args) {
        $helper->{var}{api} = $api;
        my $pm = File::Spec->catfile($base, "$path/API", "$api.pm");
        $helper->render_file('api_layout', $pm, $helper->{var});
    }
}

sub mk_conf {
    my($self, $helper, @args) = @_;

    # yml 쓰면 yml로, conf 쓰면 conf로..
    my $base = $helper->{base};

    my $conf_basename = Catalyst::Utils::appprefix($helper->{app});
    if (-e "$conf_basename.yml" || -e "$conf_basename.yaml") {
        $helper->render_file('yml', "$conf_basename.yml.new", $helper->{var});
    } elsif (-e "$conf_basename.conf") {
        $helper->render_file('conf', "$conf_basename.conf.new", $helper->{var});
    }
}

=head1 SYNOPSIS

    script/create.pl Silex::API

or

    script/create.pl Silex::API ARG1 ARG2 ARG3..

=head1 DESCRIPTION

API model wrapping DB model.
so required Generated F<Schema.pm> and F<Schema/>

please Generate F<MyApp::Schema> and sub modules like a F<MyApp::Schema::Result::Foo>
with using F<create.pl> model options

=head1 SEE ALSO

L<Catalyst::Helper>

=cut

1;

__DATA__

__model_api__
package [% app %]::Model::API;
# ABSTRACT: use a plain API class as a Catalyst model
use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model

=head1 SEE ALSO

L<[% app %]>, L<Catalyst::Model::Adaptor>

=cut

1;

__api__
package [% ns %]::API;
# ABSTRACT: Auto require [% app %] APIs
use Moose;
use namespace::autoclean;
use [% ns %]::Schema;
with qw/[% ns %]::Trait::WithAPI [% ns %]::Trait::WithDBIC [% ns %]::Trait::Log/;

sub _build_schema {
    my $self = shift;
    return [% ns %]::Schema->connect( $self->connect_info );
}

sub _build_apis {
    my $self = shift;
    my %apis;

    for my $module (qw/[% apis.join(' ') %]/) {
        my $class = __PACKAGE__ . "::$module";
        if (!Class::MOP::is_class_loaded($class)) {
            Class::MOP::load_class($class);
        }
        my $opt = $self->opts->{$module} || {};
        $apis{$module} = $class->new( schema => $self->schema, %{ $opt } );
    }

    return \%apis;
}

=head1 DESCRIPTION

[% ns %]::Schema class required

=cut

1;

__trait_Log__
package [% ns %]::Trait::Log;
# ABSTRACT: Log Trait for [% ns %]::API Role
use Moose::Role;
use namespace::autoclean;

has log => (
    is => 'ro',
    isa => 'Log::Log4perl::Logger',
    lazy_build => 1,
);

sub _build_log {
    my $self = shift;
    Log::Log4perl::init('conf/log4perl.conf');
    return Log::Log4perl->get_logger(__PACKAGE__);
}

no Moose::Role;

=head1 SYNOPSIS

    package [% ns %]::API::Something;
    use Moose;
    with '[% ns %]::Trait::Log';
    sub foo {
        my ($self) = shift;
        $self->log->debug('message');
    }

=head1 DESCRIPTION

Using Log4perl instance without Catalyst Context

=cut

1;

__trait_WithDBIC__
package [% ns %]::Trait::WithDBIC;
# ABSTRACT: DBIC Trait for [% ns %]::API Role
use Moose::Role;
use namespace::autoclean;

has schema => (
    is => 'ro',
    lazy_build => 1,
    handles => {
        txn_guard => 'txn_scope_guard',
    }
);

has connect_info => (
    is => 'ro',
    isa => 'HashRef',
);

has resultset_constraints => (
    is => 'ro',
    isa => 'HashRef',
    predicate => 'has_resultset_constraints',
);

sub resultset {
    my ($self, $moniker) = @_;

    $moniker or confess blessed($self) . "->resultset() did not receive a moniker, nor does it have a default moniker";
    $self->schema->resultset($moniker);
}

no Moose::Role;

1;

__trait_WithAPI__
package [% ns %]::Trait::WithAPI;
# ABSTRACT: API Trait for [% ns %]::API Role
use Moose::Role;
use namespace::autoclean;

has apis => (
    is => 'rw',
    isa => 'HashRef[Object]',
    lazy_build => 1,
);

has opts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

sub find {
    my ($self, $key) = @_;
    my $api = $self->apis->{$key};
    if (!$api) {
        confess "API by key $key was not found for $self";
    }
    $api;
}

no Moose::Role;

1;

__conf__
<Model API>
    class   [% ns %]::API
    <args> # ARGS of Class Constructor
        <connect_info>
            dsn                 ** DSN **           ## ex) dbi:mysql:test
            user                ** USERNAME **
            password            ** PASSWORD **
            RaiseError          1
            AutoCommit          1
            mysql_enable_utf8   1
            on_connect_do       SET NAMES utf8      ## shut the fuck up and using utf8
        </connect_info>
        # <opts>
        #     <Module>        # ARGS of [% ns %]::API::Module
        #         arg1          this is arg1
        #         arg2          this is arg2
        #     </Module>
        # </opts>
    </args>
</Model>

__yml__
"Model::API":
  class: [% ns %]::API
  args:
    connect_info:
      dsn: ** DSN **            ## ex) dbi:mysql:test
      username: ** USERNAME **
      password: ** PASSWORD **
      RaiseError:           1
      AutoCommit:           1
      mysql_enable_utf8:    1
      mysql_auto_reconnect: 1
      on_connect_do:
          - SET NAMES 'utf8'

__api_layout__
package [% ns %]::API::[% api %];
# ABSTRACT: [% ns %]::API::[% api %]
use utf8;
use Moose;
use 5.012;
use namespace::autoclean;

with qw/[% ns %]::Trait::WithDBIC [% ns %]::Trait::Log/;

sub foo {
    my ($self, $arg) = @_;
    # your stuff here
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    $c->model('API')->find('[% api %]')->foo('wtf');  ## 'World Taekwondo Federation'

=head1 DESCRIPTION

[% api %] description here

=cut

1;

__log4perl__
[% TAGS [- -] -%]
#log4perl.logger = DEBUG, A1, MAILER, Screen
log4perl.logger = DEBUG, A1, Screen
log4perl.appender.A1 = Log::Log4perl::Appender::File
log4perl.appender.A1.TZ = KST
log4perl.appender.A1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.A1.layout.ConversionPattern = [%d] [- app -] [%p] %m%n
log4perl.appender.A1.utf8 = 1
log4perl.appender.A1.filename = logs/debug.log

log4perl.appender.MAILER = Log::Dispatch::Email::MailSend
log4perl.appender.MAILER.to = ** YOUR EMAIL **
log4perl.appender.MAILER.subject = [- app -] error mail
log4perl.appender.MAILER.layout  = Log::Log4perl::Layout::PatternLayout
log4perl.appender.MAILER.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} %F(%L) %M [%p] %m %n
log4perl.appender.MAILER.Threshold = ERROR

log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %m %n
