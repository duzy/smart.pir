#
#    Copyright 2008-11-28 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#
#

=head1 NAME

Smart::Test::Unit - a unit test tool for smart-make

=head1 SYNOPSIS

Example usage:

  use Smart::Test::Unit path => 't';

  # or

  use Smart::Test::Unit files => [ 't/*.t' ];

=cut

package Smart::Test::Unit;

use strict;
use warnings;
#use 5.8;
use Carp;
use File::Spec;
use Smart::Test;

sub collect_files {
    my %options = @_;
    my @files;

    if ( $options{path} && ref $options{path} eq 'ARRAY' ) {
	my @pathes = @{ $options{path} };
	push @files, map { glob(File::Spec->catfile( $_, '*.t' )) } @pathes;
    }
    elsif ( $options{path} && ref $options{path} eq 'STRING' ) {
        push @files, glob( File::Spec->catfile( $options{path}, '*.t' ) );
    }

    if ( $options{files} && ref $options{files} eq 'ARRAY' ) {
        my @patterns = @{ $options{files} };
        push @files, map { glob( $_ ) } @patterns;
    }
    elsif ( $options{files} && ref $options{files} eq 'STRING' ) {
	push @files, glob( $options{files} );
    }

    return @files;
}

sub import {
    my ( $class, %options ) = @_;

    croak "Should tell the smart command\n"
        unless my $smart = $options{smart};

    croak "Should tell the 'path' or 'files'\n"
        unless $options{path} or $options{files};

    exit unless my @files = collect_files( %options );

    #print map { "unit: " . $_ . "\n" } @files;

    my $tester = Smart::Test->new;
    $tester->runtests( $smart, @files );
}

1;

