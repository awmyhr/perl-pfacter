package Pfacter::_timestamp;

#
use POSIX qw(strftime);

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    $r =  strftime "%F %T %z", localtime;

    if ( $r ) { return( $r ); }
    else      { return( 0 ); }
}

1;
