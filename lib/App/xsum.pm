package App::xsum;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{xsum} = {
    v => 1.1,
    links => [
        {
            url => 'prog:shasum',
            summary => 'Script which comes with the perl distribution',
        },
        {
            url => 'prog:md5sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha1sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha256sum',
            summary => 'Unix utility',
        },
    ],
};
sub xsum {
    my %args = @_;
}

1;
#ABSTRACT: Compute and check file checksums/digests

=head1 SYNOPSIS

See L<xsum>.


=head1 SEE ALSO

Backend module: L<File::Digest>, which in turn uses L<Digest::CRC>,
L<Digest::MD5>, and L<Digest::SHA>.
