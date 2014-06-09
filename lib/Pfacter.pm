package Pfacter;

our $VERSION = '1.14';

sub modulelist {
    my $self   = shift;
    my $kernel = shift;
    my $ver1   = shift;
    my @modules;

    if ( $ver1 == 1 ) { 
        push @modules, qw(

            architecture
            disk
            domain
            filesystems
            fqdn
            hardwaremanufacturer
            hardwaremodel
            hardwareplatform
            hardwareproduct
            hostname
            ipaddress
            kernel
            kernelrelease
            kernelversion
            localtime
            macaddress
            memory
            memorytotal
            netmask
            operatingsystem
            processor
            processorcount
            productid
            serialnumber
            swap
            uniqueid
        );
    } else {
        push @modules, qw(

            architecture
            domain
            filesystems
            fqdn
            hardwaremodel
            hostname
            ipaddress
            kernel
            kernelrelease
            kernelversion
            macaddress
            netmask
            operatingsystem
            processor
            processorcount
            serialnumber
            uniqueid
        );
    }
    
    # Kernel-specific
    for ( $kernel ) {
        /Linux/ && do {
            push @modules, qw(

                lsbcodename
                lsbdescription
                lsbid
                lsbrelease

            );
        };
    }

    # Application-specific
    if ( -e '/var/cfengine/bin/cfagent' ) {
        push @modules, qw(

            cfclasses
            cfversion

        );
    }

    if ( -e '/usr/bin/puppet' ) {
        push @modules, qw(

            puppetversion

        );
    }

    return sort @modules;
}

1;
