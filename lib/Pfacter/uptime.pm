package Pfacter::uptime;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    $c = '/usr/bin/uptime'  if -e '/usr/bin/uptime';

    if ( $c ) {
        @d = split(',', qx( $c ));
       $r = $1 if $d[0] =~ /^.+up\s+(.+)/;
    }

    if ( $r ) { return( $r ); }
    else      { return( 0 ); }
}

1;
