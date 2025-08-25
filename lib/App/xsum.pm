package App::xsum;

use 5.010001;
use strict;
use warnings;

our %SPEC;

# AUTHORITY
# DATE
# DIST
# VERSION

$SPEC{xsum} = {
    v => 1.1,
    summary => 'Compute and check file checksums/digests (using various algorithms)',
    description => <<'MARKDOWN',

`xsum` is a handy small utility that can be used as an alternative/replacement
for the individual per-algorithm Unix utilities like `md5sum`, `sha1sum`,
`sha224sum`, and so on. It's basically the same as said Unix utilities but you
can use a single command instead.

The backend of `xsum` is a Perl module <pm:File::Digest> which in turn delegates
to the individual per-algorithm backend like <pm:Digest::MD5>, <pm:Digest::SHA>,
and so on. Most of the backend modules are written in C/XS so you don't suffer
significant performance decrease.

MARKDOWN
    args => {
        tag => {
            summary => 'Create a BSD-style checksum',
            schema => ['bool', is=>1],
        },
        check => {
            summary => 'Read checksum from files and check them',
            schema => ['bool', is=>1],
            cmdline_aliases => {c=>{}},
        },
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        checksums => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            summary => 'Supply checksum(s)',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {C=>{}},
        },
        algorithm => {
            schema => ['str*', in=>[qw/crc32 md5 sha1 sha224 sha256 sha384 sha512 sha512224 sha512256 Digest/]],
            description => <<'MARKDOWN',

In addition to `md5`, `sha1` or the other algorithms, you can also specify
`Digest` to use Perl's <pm:Digest> module. This gives you access to tens of
other digest modules, for example <pm:Digest::BLAKE2> (see examples).

When `--digest-args` (`-A`) is not specified, algorithm defaults to `md5`. But
if `--digest-args` (`-A`) is specified, algorithm defaults to `Digest`, for
convenience.

MARKDOWN
            cmdline_aliases => {a=>{}},
        },
        digest_args => {
            schema => ['array*',

                       # comment out temporarily, Perinci::Sub::GetArgs::Argv
                       # clashes with coerce rules; we should fix
                       # Perinci::Sub::GetArgs::Argv to observe coercion rules
                       # first
                       #of=>'str*',

                       'x.perl.coerce_rules'=>['From_str::comma_sep']],
            description => <<'MARKDOWN',

If you use `Digest` as the algorithm, you can pass arguments for the <pm:Digest>
module here.

MARKDOWN
            cmdline_aliases => {A=>{}},
            completion => sub {
                # due to coerce rule 'str_comma_sep', 'completion' instead of
                # 'element_completion' is invoked. we need to split and merge
                # comma-separated list ourself.

                require Complete::Util;

                my %args = @_;
                my $word  = $args{word};

                my @words = split ",", $word, -1;
                #use DD; dd \@words;

                if (@words <= 1) {
                    require Complete::Module;
                    my $answer = Complete::Util::arrayify_answer(
                        Complete::Module::complete_module(
                            ns_prefix => 'Digest',
                            word => $words[0] // '',
                        ),
                    );
                    # remove Digest::* modules that we know isn't a "proper" Digest module
                    # or that we don't want.
                    $answer = [ grep {!/^(base|file)$/} @$answer];
                    return $answer;
                } elsif (@words) {
                    my $digest_module = $words[0];
                    my $last_word = $words[-1];
                    my $prefix = join(",", @words[0..$#words-1]);
                    my $arg_completion;

                    #use DD; dd {digest_module=>$digest_module, last_word=>$last_word};
                    if ($digest_module eq 'BLAKE2') {
                        if (@words == 2) {
                            $arg_completion = Complete::Util::complete_array_elem(
                                array => ['blake2s', 'blake2b'],
                                word => $last_word,
                            );
                        }
                    } elsif ($digest_module eq 'SHA') {
                        if (@words == 2) {
                            $arg_completion = Complete::Util::complete_array_elem(
                                array => [qw/1 256 384 512/],
                                word => $last_word,
                            );
                        }
                    } elsif ($digest_module eq 'CRC') {
                        # args for Digest::CRC is key=>value pairs.
                        my @pairs = @words; shift @pairs;
                        if (@pairs % 2) {
                            # completing key
                            pop @pairs;
                            my %pairs = @pairs;
                            $arg_completion = Complete::Util::arrayify_answer(
                                Complete::Util::complete_array_elem(
                                    array   => [qw/type width init xorout refout poly refin cont/],
                                    word    => $last_word,
                                    exclude => [keys %pairs], # keys already specified
                                ),
                            );
                        } else {
                            # completing value
                            my $key = $words[-2];
                            if ($key eq 'type') {
                                $arg_completion = Complete::Util::complete_array_elem(
                                    array=>[qw/crc8 crc16 crc32 crc64 crcccitt crcopenpgparmor/],
                                    word=>$last_word,
                                );
                            } elsif ($key eq 'width') {
                                $arg_completion = Complete::Util::complete_array_elem(
                                    array=>[qw/8 16 32 64/],
                                    word=>$last_word,
                                );
                            }
                        }
                    } elsif ($digest_module eq 'Bcrypt') {
                        # args for Digest::Bcrypt is key=>value pairs.
                        my @pairs = @words; shift @pairs;
                        if (@pairs % 2) {
                            # completing key
                            pop @pairs;
                            my %pairs = @pairs;
                            $arg_completion = Complete::Util::arrayify_answer(
                                Complete::Util::complete_array_elem(
                                    array   => [qw/cost salt settings/],
                                    word    => $last_word,
                                    exclude => [keys %pairs], # keys already specified
                                ),
                            );
                        } else {
                            # completing value
                            my $key = $words[-2];
                            if ($key eq 'cost') {
                                # ...
                            }
                        }
                    }

                    goto RETURN_AS_IS unless $arg_completion && @$arg_completion;
                    return [map {"$prefix,$_"} @$arg_completion];
                } else {
                }
              RETURN_AS_IS:
                return [$word, "$word "];
            }
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
            url => 'prog:sha224sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha256sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha384sum',
            summary => 'Unix utility',
        },
        {
            url => 'prog:sha512sum',
            summary => 'Unix utility',
        },
    ],
    examples => [
        {
            summary => 'Compute MD5 digests for some files',
            src => 'xsum -a md5 *.dat',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compute MD5 digests for some files (same as previous example, -a defaults to "md5")',
            src => 'xsum *.dat',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compute MD5 digests for some files (also same as previous example)',
            src => 'xsum -a Digest -A MD5 *.dat',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compute MD5 digests for some files (also same as previous example, -a defaults to "Digest" when -A is specified)',
            src => 'xsum -A MD5 *.dat',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compute BLAKE2b digests for some files (requirest Digest::BLAKE2 Perl module)',
            src => 'xsum -A BLAKE2,blake2b *.dat',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Compute SHA1 digest for data in stdin',
            src => 'somecmd | xsum -a sha1 -',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Check MD5 digests of files listed in MD5SUMS',
            src => 'xsum --check MD5SUMS',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Check MD5 digest of one file',
            src => 'xsum download.exe -C 9f4b2277f50a412e56de6e0306f4afb8',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Check MD5 digest of two files',
            src => 'xsum download1.exe -C 9f4b2277f50a412e56de6e0306f4afb8 download2.zip -C 62b3bf86abdfdd87e9f6a3ea7b51aa7b',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    'cmdline.skip_format' => 1,
};
sub xsum {
    require File::Digest;
    require Parse::Sums;

    my %args = @_;

    my $algorithm = $args{algorithm} // ($args{digest_args} ? 'Digest' : 'md5');

    my $num_success;
    my $envres;
    my $i = -1;
    for my $file (@{ $args{files} }) {
        $i++;
        if ($args{check}) {

            # treat file as checksums file. extract filenames and checksums from
            # the checksums file and check them.
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
                if (lc($digest_res->[2]) eq lc($entry->{digest})) {
                    print "$entry->{file}: OK\n";
                    $num_success++;
                } else {
                    $envres //= [
                        500, "Some files did NOT match computed checksums"];
                    print "$entry->{file}: FAILED\n";
                }
            }

        } elsif ($args{checksums} && @{ $args{checksums} }) {

            # check checksum of file against checksum provided in 'checksums'
            # argument.
            if ($#{ $args{checksums} } < $i) {
                warn "No checksum value provided for file '$file', please specify with -C\n";
                next;
            }
            my $digest_res = File::Digest::digest_file(
                file => $file, algorithm => $algorithm, digest_args=> $args{digest_args});
            unless ($digest_res) {
                $envres //= [
                    500, "Some files' checksums cannot be checked"];
                warn "$file: Cannot compute digest: $digest_res->[1]\n";
                next;
            }
            if (lc($digest_res->[2]) eq lc($args{checksums}[$i])) {
                print "$file: OK\n";
                $num_success++;
            } else {
                $envres //= [
                    500, "Some files did NOT match computed checksums"];
                print "$file: FAILED\n";
            }

        } else {

            # produce checksum for file
            my $res = File::Digest::digest_file(
                file => $file, algorithm => $algorithm, digest_args=> $args{digest_args});
            unless ($res->[0] == 200) {
                warn "Can't checksum $file: $res->[1]\n";
                next;
            }
            $num_success++;
            if ($args{tag}) {
                printf "%s (%s) = %s\n", uc($algorithm), $file, $res->[2];
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

L<sum> from L<PerlPowerTools> (which only supports older algorithms like CRC32).
