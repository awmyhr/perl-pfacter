package Pfacter::orgenv;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my @dirs = ($ENV{"HOME"} . '/etc/puppet/orgenv', '/etc/puppet/orgenv', '/etc/environment');
    my ( $r, $f );

    foreach (@dirs){
        if ( -e $_ ) { $f = $_; }
    }
    
    if ( -e $f ) {
        open envFile, $f || return( 0 );
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
