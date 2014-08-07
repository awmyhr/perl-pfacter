package Pfacter::os;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );
    my $rel = $p->{'kernelversion'};

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            $r = 'AIX ' . $rel;
        };

        /Darwin/ && do {
            $r = 'OSX ' . $rel;
        };

        /FreeBSD/ && do {
            $r = 'FreeBSD ' . $rel;
        };

        /Linux/ && do {
            if ( -e '/etc/debian_version' ) { $r = 'Debian ' . $rel; }
            if ( -e '/etc/gentoo-release' ) { $r = 'Gentoo ' . $rel; }
            if ( -e '/etc/fedora-release' ) { $r = 'Fedora ' . $rel; }
            if ( -e '/etc/redhat-release' ) { $r = 'RedHat ' . $rel; }
            if ( -e '/etc/SuSE-release' )   { $r = 'SuSE ' . $rel; }
        };

        /SunOS/ && do {
            $r = 'Solaris ' . $rel;
        };

        /SCO_SV/ && do {
            $r = 'SCO UNIX ' . $rel;
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
