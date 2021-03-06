package Imp::Portage;

use strict;
use warnings;
use 5.010;

use Moo;
use Sys::Hostname;
use autodie;

use Imp::Portage::Emerge;
use Imp::Portage::Config;
use Imp::Portage::Eix;
use Imp::Environment;

has emerge => ( is => 'rw' );
has eix    => ( is => 'rw' );
has env    => ( is => 'rw', required => 1 );

sub BUILD {
    my $self = shift;
    Imp::Portage::Config->_make_base;
    $self->emerge( Imp::Portage::Emerge->new );
    $self->eix( Imp::Portage::Eix->new );
    eval { $self->eix->eix_update };

    if ($@) {
        $self->install( 'eix', 1 );
        $self->eix->eix_update;
    }
}

sub install {
    my $self      = shift;
    my $pkg       = shift;
    my $bootstrap = shift;

    if ( !$bootstrap && $self->eix->eix_installed($pkg) ) {
        say "package is already installed $pkg";
        return;
    }
    $self->emerge->install($pkg);
}

sub update {
    my $self = shift;
    $self->emerge->update;
}

sub config {
    my $self     = shift;
    my $template = shift;
    my $output   = shift;
    my $data     = $self->env->env;
    my $config   = Imp::Portage::Config->new(
        template => $template,
        output   => $output,
        data     => $data,
    );
    $config->write;
}

sub unkeyword {
    my $self            = shift;
    my $package         = shift;
    my $version         = shift;
    my $escaped_version = $version;
    $escaped_version =~ s/\./-/g;
    my $escaped = $package;
    $escaped =~ s/\//-/g;
    if ( !-f "/etc/portage/package.accept_keywords/$escaped-$escaped_version" ) {
        open my $fh, '>>', "/etc/portage/package.accept_keywords/$escaped-$escaped_version";
        print $fh "=$package-$version ~amd64\n";
        close($fh);
    }
}

sub unmask {
    my $self            = shift;
    my $package         = shift;
    my $version         = shift;
    my $escaped_version = $version;
    $escaped_version =~ s/\./-/g;
    my $escaped = $package;
    $escaped =~ s/\//-/g;
    if ( !-f "/etc/portage/package.unmask/$escaped-$escaped_version" ) {
        open my $fh, '>>', "/etc/portage/package.unmask/$escaped-$escaped_version";
        print $fh "=$package-$version\n";
        close($fh);
    }
}

1;
