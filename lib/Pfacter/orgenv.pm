package Pfacter::orgenv;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    # NOTE: whis will not work for AIX
    if ( -e '/etc/environment' ) {
        open envFile, '/etc/environment' || return( 0 );
        $r = <envFile>;
        close envFile;

        if ( $r ) { $r = $1 if $r =~ /^(\w+)\..*$/; }

        return $r ;
    }
    else {
        return( 0 );
    }
}

1;
