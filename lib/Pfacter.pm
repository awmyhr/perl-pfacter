package Pfacter;

our $VERSION = 'p2.00b';

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

            _timestamp
            architecture
            domain
            filesystems
            fqdn
            hardwareisa
            hardwaremodel
            hostname
            ipaddress
            kernel
            kernelrelease
            kernelversion
            macaddress
            manufacturer
            memorysize
            netmask
            operatingsystem
            operatingsystemrelease
            osfamily
            physicalprocessorcount
            processor
            processor0
            processorcount
            serialnumber
            timezone
            swapsize
            uniqueid
            uptime
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
