package Pfacter::hostname;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Darwin|FreeBSD|Linux|SunOS|SCO_SV/ && do {
            if ( -e '/bin/hostname' ) {
                $r = qx( /bin/hostname );
                $r = $1 if $r =~ /^(\w+)\..*$/;
            } elsif ( -e '/usr/bin/hostname' ) {
                $r = qx( /usr/bin/hostname );
                $r = $1 if $r =~ /^(\w+)\..*$/;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
