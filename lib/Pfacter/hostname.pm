package Pfacter::hostname;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    $r =  qx( /bin/hostname ) if ( -e '/bin/hostname' );
    $r =  qx( /usr/bin/hostname ) if ( -e '/usr/bin/hostname' );

    if ( $r ) { $r = $1 if $r =~ /^(\w+)\..*$/; }

    if ( $r ) { return( $r ); }
    else      { return( 0 ); }
}

1;
