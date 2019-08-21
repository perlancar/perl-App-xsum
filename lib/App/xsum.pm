package App::xsum;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{xsum} = {
    v => 1.1,
    summary => 'Compute and check file checksums/digests (using various algorithms)',
    description => <<'_',

`xsum` is a handy utility as an alternative/replacement to the individual
per-algorithm utilities like `md5sum`, `sha1sum`, `sha224sum`, and so on. It is
a CLI for <pm:File::Digest> which in turn delegates to the individual
per-algorithm backend like <pm:Digest::MD5>, <pm:Digest::SHA>, and so on.

_
    args => {
        tag => {
            summary => 'Create a BSD-style checksum',
            schema => ['bool', is=>1],
        },
        check => {
            summary => 'Read checksum from files and check them',
            schema => ['bool', is=>1],
        },
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        algorithm => {
            schema => ['str*', in=>[qw/crc32 md5 sha1 sha224 sha256 sha384 sha512 sha512224 sha512256/]],
            default => 'md5',
            cmdline_aliases => {a=>{}},
        },
    },
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
    'cmdline.skip_format' => 1,
};
sub xsum {
    require File::Digest;
    require Parse::Sums;

    my %args = @_;

    my $num_success;
    my $envres;
    for my $file (@{ $args{files} }) {
        if ($args{check}) {
            my $res = Parse::Sums::parse_sums(filename => $file);
            unless ($res->[0] == 200) {
                $envres //= [
                    500, "Some checksums files cannot be parsed"];
                warn "Can't parse checksums from $file: $res->[1]\n";
                next;
            }
            unless (@{ $res->[2] }) {
                $envres //= [
                    500, "Some checksums files don't contain any checksums"];
                warn "No checksums found in $file".($res->[3]{'func.warning'} ? ": ".$res->[3]{'func.warning'} : "")."\n";
                next;
            }
            warn "$file: ".$res->[3]{'func.warning'}."\n" if $res->[3]{'func.warning'};
          ENTRY:
            for my $entry (@{ $res->[2] }) {
                my $digest_res = File::Digest::digest_file(
                    file => $entry->{file}, algorithm => $entry->{algorithm});
                unless ($digest_res) {
                    $envres //= [
                        500, "Some files' checksums cannot be checked"];
                    warn "$entry->{file}: Cannot compute digest: $digest_res->[1]\n";
                    next ENTRY;
                }
                if ($digest_res->[2] eq $entry->{digest}) {
                    print "$entry->{file}: OK\n";
                    $num_success++;
                } else {
                    $envres //= [
                        500, "Some files did NOT match computed checksums"];
                    print "$entry->{file}: FAILED\n";
                }
            }
        } else {
            my $res = File::Digest::digest_file(
                file => $file, algorithm => $args{algorithm});
            unless ($res->[0] == 200) {
                warn "Can't checksum $file: $res->[1]\n";
                next;
            }
            $num_success++;
            if ($args{tag}) {
                printf "%s (%s) = %s\n", uc($args{algorithm}), $file, $res->[2];
            } else {
                printf "%s  %s\n", $res->[2], $file;
            }
        }
    }

    return $envres if $envres;
    $num_success ? [200] : [500, "All files failed"];
}

1;
#ABSTRACT:

=head1 SYNOPSIS

See L<xsum>.


=head1 append:SEE ALSO

Backend module: L<File::Digest>, which in turn uses L<Digest::CRC>,
L<Digest::MD5>, and L<Digest::SHA>.
