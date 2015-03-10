package Pfacter::timezone;

#
use POSIX qw(strftime);

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    $r =  strftime "%Z", localtime;

    if ( $r ) { return( $r ); }
    else      { return( 0 ); }
}

1;
