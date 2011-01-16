package CPAN::Mini::Webserver::Templates;
use strict;
use warnings;
use Template::Declare::Tags;
use base 'Template::Declare';

private template 'header' => sub {
    my ( $self, $title ) = @_;

    head {
        title {$title};
        link {
            attr {
                rel   => 'stylesheet',
                href  => '/static/css/screen.css',
                type  => 'text/css',
                media => 'screen, projection'
            }
        };
        link {
            attr {
                rel   => 'stylesheet',
                href  => '/static/css/print.css',
                type  => 'text/css',
                media => 'print'
            }
        };
        outs_raw
            '<!--[if IE]><link rel="stylesheet" href="/static/css/ie.css" type="text/css" media="screen, projection"><![endif]-->';
        link {
            attr {
                rel  => 'icon',
                href => '/static/images/favicon.png',
                type => 'image/png',
            }
        };
        link {
            attr {
                rel   => 'search',
                href  => '/static/xml/opensearch.xml',
                type  => 'application/opensearchdescription+xml',
                title => 'minicpan search',
            }
        };

        meta { attr { generator => 'CPAN::Mini::Webserver' } };
    }
};

private template 'footer' => sub {
    my $self    = shift;
    my $version = $CPAN::Mini::Webserver::VERSION;

    div {
        attr { id => "footer" };
        small {
            "Generated by CPAN::Mini::Webserver $version";
        };
    }
};

private template 'author_link' => sub {
    my ( $self, $author_desc, $arguments ) = @_;

    my $author = $author_desc;
    $author = $arguments->{parse_cpan_authors}->author( $author_desc ) if !$author_desc->isa('Parse::CPAN::Authors::Author');

    my $name = my $pause_id = $author_desc;
    $name = $author->name if $author;
    $pause_id = $author->pauseid if $author;

    a {
        attr { href => '/~' . lc( $pause_id ) . '/' };
        $name;
    };
};

private template 'distribution_link' => sub {
    my ( $self, $distribution ) = @_;
    a {
        attr {    href => '/~'
                . lc( $distribution->cpanid ) . '/'
                . $distribution->distvname
                . '/' };
        $distribution->distvname;
    };
};

private template 'package_link' => sub {
    my ( $self, $package ) = @_;
    my $distribution = $package->distribution;
    a {
        attr {    href => '/package/'
                . lc( $distribution->cpanid ) . '/'
                . $distribution->distvname . '/'
                . $package->package
                . '/' };
        $package->package;
    };
};

private template distribution_file => sub {
    my ( $self, $pauseid, $distvname, $filename ) = (@_);

    my $display_filename
        = ( $filename =~ /^$distvname\/(.*)$/ )
        ? $1
        : $filename;
    my $href
        = ( $filename =~ /\.(pm|pod)$/ )
        ? "/~$pauseid/$distvname/$filename"
        : "/raw/~$pauseid/$distvname/$filename";
    row {
        cell {
            a {
                attr { href => $href };
                span {
                    $display_filename;
                };
            };
        };
    };
};

private template 'searchbar' => sub {
    my $self = shift;
    my $q    = shift;

    table {
        row {
            form {
                attr { name => 'f', method => 'get', action => '/search/' };
                cell {
                    attr { class => 'searchbar' };
                    outs_raw
                        q|<a href="/"><img src="/static/images/logo.png"></a>|;
                };
                cell {
                    attr { class => 'searchbar' };
                    input {
                        { attr { type => 'text', name => 'q', value => $q } };
                    };
                    input {
                        {
                            attr {
                                type  => 'submit',
                                value => 'Search Mini CPAN'
                                }
                        };
                    };
                };
            };
        };
    };
};

private template 'search_results' => sub {
    my ( $self, $arguments ) = @_;
    my $q                  = $arguments->{q};
    my @authors            = @{ $arguments->{authors} };
    my @distributions      = @{ $arguments->{distributions} };
    my @packages           = @{ $arguments->{packages} };
    if ( @authors + @distributions + @packages ) {
        outs_raw '<table>';
        foreach my $author (@authors) {

            row {
                cell {
                    show( 'author_link', $author );

                };
            };
        }

        foreach my $distribution (@distributions) {
            row {
                cell {
                    show( 'distribution_link', $distribution );
                    outs ' by ';
                    show( 'author_link', $distribution->cpanid, $arguments );
                };
            };
        }
        foreach my $package (@packages) {
            row {
                cell {
                    show( 'package_link', $package );
                    outs ' by ';
                    show( 'author_link', $package->distribution->cpanid, $arguments );
                };
            };
        }
        outs_raw '</table>';
    } else {
        p {'No results found.'};
    }
};

template 'index' => sub {
    my ( $self, $arguments ) = @_;
    my $recents            = $arguments->{recents};

    html {
        attr { xmlns => 'http://www.w3.org/1999/xhtml' };
        div {
            attr { class => 'container' };
            div {
                attr { class => 'span-24' };
                show( 'header', 'Index' );
                body {
                    attr { onload => 'document.f.q.focus()' };
                    show('searchbar');
                    h1 {'Index'};
                    p {'Welcome to CPAN::Mini::Webserver. Start searching!'};
                    if ($recents->{count}) {
                        h2 {'Recent distributions'};
                        ul {
                            foreach my $recent (@{$recents->{display_list}}) {
                                my $cpanid    = $recent->cpanid;
                                my $distvname = $recent->distvname;
                                next unless $distvname;
                                li {
                                    a {
                                        attr {    href => '/~'
                                                . lc($cpanid) . '/'
                                                . $distvname };
                                        $distvname;
                                    };
                                    outs ' by ';
                                    show( 'author_link', $cpanid, $arguments );
                                }
                            }
                        };
                        p{
                            attr { class => 'small' };
                            "(And " . ($recents->{count} - @{$recents->{display_list}} . " more.)");
                        } if $recents->{count} > 20;
                    }
                };
                show('footer');
            };
        };
    };
};

template '404' => sub {
    my ( $self, $arguments ) = @_;
    my $q = $arguments->{q};
    html {
        attr { xmlns => 'http://www.w3.org/1999/xhtml' };
        div {
            attr { class => 'container' };
            div {
                attr { class => 'span-24' };
                show( 'header', 'File not found' );
                body {
                    show( 'searchbar', $q );
                    h1 {'Sorry. I couldn\'t find the page you wanted.'};
                    p {
                        "Unfortunately, the page you were looking for doesn't exist. Perhaps a quick search for $q will turn up what you were looking for:";
                    };
                };
                h2 {
                    outs "Search for ";
                    outs_raw '&#147;';
                    outs $q;
                    outs_raw '&#148;';
                };
                show( 'search_results', $arguments );
                show('footer');
            };
        };
    };
};

template 'search' => sub {
    my ( $self, $arguments ) = @_;
    my $q = $arguments->{q};
    html {
        show( 'header', "Search for `$q'" );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show( 'searchbar', $q );
                    h1 {
                        outs "Search for ";
                        outs_raw '&#147;';
                        outs $q;
                        outs_raw '&#148;';
                    };
                    show( 'search_results', $arguments );
                    show('footer');
                }
            };
        }
    };
};

private template 'authorinfo' => sub {
    my ( $self, $author ) = @_;

    my $pauseid = $author->pauseid;
    my $email   = $author->email;
    my $url     = $author->can('homepage') ? $author->homepage : undef;
    my $prefix
        = 'id' . '/'
        . substr( $pauseid, 0, 1 ) . '/'
        . substr( $pauseid, 0, 2 ) . '/'
        . $pauseid;

    h2 {"Links"};
    ul {
        li {
            a {
                attr { href => "http://backpan.perl.org/authors/$prefix" };
                'BackPAN';
            };
        }
        li {
            a {
                attr { href => "mailto:$email" };
                $email;
            };
        }
        li {
            a {
                attr { href => $url };
                $url;
            };
        }
        li {
            a {
                attr { href =>
                        "http://cpantesters.perl.org/author/$pauseid.html" };
                'CPANTesters';
            };
        }
        li {
            a {
                attr { href =>
                        "http://bbbike.radzeit.de/~slaven/cpantestersmatrix.cgi?author=$pauseid"
                };
                'Test Matrix';
            };
        }
    }
};

template 'author' => sub {
    my ( $self, $arguments ) = @_;
    my $author        = $arguments->{author};
    my $pauseid       = $arguments->{pauseid};
    my $distvname     = $arguments->{distvname};
    my @distributions = @{ $arguments->{distributions} };
    my $dates         = $arguments->{dates};

    html {
        show( 'header', $author->name );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24 last' };
                    show('searchbar');
                    h1 { show( 'author_link', $author ) };
                }
                div {
                    attr { class => 'span-18 last' };
                    outs_raw '<table>';
                    foreach my $distribution (@distributions) {
                        row {
                            cell {
                                show( 'distribution_link', $distribution );

                            };
                            cell {
                                outs $dates->{ $distribution->distvname };
                            };
                        };
                    }
                    outs_raw '</table>';
                }
                div {
                    attr { class => 'span-6 last' };
                    show( 'authorinfo', $author );
                };

                div {
                    attr { class => 'span-24 last' };
                    show('footer');
                };

            };
        };

    }
};

private template 'dependencies' => sub {
    my ( $self, $meta, $pcp ) = @_;

    my @dep_types = qw(requires build_requires configure_requires);
    @dep_types = grep defined $meta->{$_}, @dep_types;

    div {
        attr { class => 'dependencies' };
        h2 {'Dependencies'};
        for my $deptype ( @dep_types ) {
            my ($is_spec_req) = $deptype =~ /(.*?)_/;
            outs "$is_spec_req requirements:" if $is_spec_req;
            ul {
                for my $package ( sort keys %{ $meta->{$deptype} } ) {
                    next if $package eq 'perl';
                    li {
                        dep_link( $pcp, $package );
                    };
                }
            }
        }
    }
};

sub dep_link {
    my ( $pcp, $package ) = @_;

    my $p = $pcp->package($package);
    return outs $package if !$p;

    my $d = $p->distribution;
    return outs $package if !$d;

    my $distvname = $d->distvname;
    my $author    = $d->cpanid;
    a {
        attr { href => "/~$author/$distvname/" };
        $package;
    };
    return;
}

private template 'metadata' => sub {
    my ( $self, $meta ) = @_;

    h2 {'Metadata'};
    div {
        attr { class => 'metadata' };
        dl {
            foreach
                my $key ( qw(abstract license repository), 'release date' )
            {
                if ( defined $meta->{$key} ) {
                    dt { ucfirst $key; };
                    if ( defined $meta->{resources}->{$key} ) {
                        a {
                            attr {
                                href => delete $meta->{resources}->{$key} };
                            $meta->{$key};
                        };
                    } else {
                        dd { $meta->{$key} };
                    }
                }
            }
            foreach my $datum ( keys %{ $meta->{resources} } ) {
                dt { ucfirst $datum; }
                dd {
                    a {
                        attr { href => $meta->{resources}->{$datum}; };
                        $meta->{resources}->{$datum};
                    }

                }
            }
        }
    };
};

private template 'download' => sub {
    my ( $self, $author, $distribution ) = @_;
    my $distvname = $distribution->distvname;
    h2 {'Download'};
    div {
        a {
            attr { href => '/download/~' . $author->pauseid . "/$distvname" };
            $distribution->filename;
        }
    };
};

private template 'install' => sub {
    my ( $self, $author, $distribution, $filenames ) = @_;
    my $distvname = $distribution->distvname;

    # Check whether we have the module/distribution installed
    # And display the status
    # Just fudge:
    # * If we have lib/*.pm, that's a contained module
    my @modules = map {
        m![^/]*/lib/(.*?)\.pm!;
        $_ = $1;
        s!/!::!g;
        $_
        } grep {
        m![^/]*/lib/.*?\.pm$!
        } @{$filenames};

    my $installed_version = Module::InstalledVersion->new( $modules[0] );

    my $msg    = "Not installed on this Perl";
    my $action = 'Install';
    if ( $installed_version->{version} ) {
        $msg = sprintf 'You have version %s installed.',
            $installed_version->{version};
        if ( $installed_version->{version} lt $distribution->version ) {
            $action = 'Update';
        } elsif ( $installed_version->{version} eq $distribution->version ) {
            $action = 'Reinstall';
        } else {
            $action = 'Downgrade';
        }
    }

    h2 {'Install'};
    div {
        attr { class => 'install' };
        div { attr { 'class' => "install-message" }; $msg };
        form {
            attr { class => 'install-link' } attr { method => 'PUT' };
            attr {
                      action => '/install/~'
                    . lc( $distribution->cpanid ) . '/'
                    . $distribution->distvname . '/'
                    . $distribution->filename;
            };
            button {$action} $action;
        };
    };
};

private template 'dist_links' => sub {
    my ( $self, $distribution ) = @_;
    my $distname = $distribution->dist;

    h2 {'Links'};
    ul {
        li {
            outs "Test ";
            a {
                attr { href =>
                        "http://bbbike.radzeit.de/~slaven/cpantestersmatrix.cgi?dist=$distname"
                };
                "matrix";
            };
            outs " and ";
            a {
                attr { href =>
                        "http://cpantesters.perl.org/show/$distname.html" };
                "reports";
            };
        }
        li {
            a {
                attr { href =>
                        "http://rt.cpan.org/NoAuth/Bugs.html?Dist=$distname"
                };
                "RT";
            };
            outs " (or via ";
            a {
                attr { href => "mailto:bug-$distname\@rt.cpan.org" } "email";
            };
            outs ")";
        }
        li {
            a {
                attr { href => "http://annocpan.org/dist/$distname" };
                "AnnoCPAN";
            }
        }
        li {
            a {
                attr { href => "http://cpanratings.perl.org/d/$distname" };
                "CPAN Ratings";
            }
        }
    }
};

template 'filelist' => sub {
    my ( $self, $pauseid, $distvname, $label, $filenames ) = @_;
    h2 {$label};
    outs_raw '<table>';
    foreach my $filename (@$filenames) {
        show(
            distribution_file => $pauseid,
            $distvname, $filename
        );
    }
    outs_raw '</table>';
};

template 'distribution' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};
    my $distribution = $arguments->{distribution};
    my @filenames    = @{ $arguments->{filenames} };
    my $meta         = $arguments->{meta};
    my $pcp          = $arguments->{pcp};
    html {
        show( 'header', $author->name . ' > ' . $distvname );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24 last' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                    };
                }
                div {
                    attr { class => 'span-18 last' };

                    #                    outs_raw '<table>';
                    my ( @code, @test, @other, @doc );
                    foreach (@filenames) {
                        if ( m{(?:/bin/|\.p(?:m|l)$)} and not m{/inc/} ) {
                            push @code, $_;
                        } elsif (m{\.pod$}) {
                            push @doc, $_;
                        } elsif (/\.t$/) {
                            push @test, $_;
                        } else {
                            push @other, $_;
                        }
                    }
                    show( 'filelist', $pauseid, $distvname, 'Code', \@code )
                        if @code;
                    show( 'filelist', $pauseid, $distvname, 'Documentation',
                        \@doc )
                        if @doc;
                    show( 'filelist', $pauseid, $distvname, 'Tests', \@test )
                        if @test;
                    show( 'filelist', $pauseid, $distvname, 'Other', \@other )
                        if @other;

                   #                    foreach my $filename (@filenames) {
                   #                        show(
                   #                            distribution_file => $pauseid,
                   #                            $distvname, $filename
                   #                        );
                   #                    }
                   #                    outs_raw '</table>';
                };
                div {
                    attr { class => 'span-6 last' };
                    show( 'metadata',     $meta );
                    show( 'dependencies', $meta, $pcp );
                    show( 'download',     $author, $distribution );
                    show( 'install',    $author, $distribution, \@filenames );
                    show( 'dist_links', $distribution );
                };
                div {
                    attr { class => 'span-24 last' };
                    show('footer');
                };

            }

        };

    }
};

template 'file' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $distribution = $arguments->{distribution};
    my $filename     = $arguments->{filename};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};

    my $file     = $arguments->{filename};
    my $contents = $arguments->{contents};
    my $html     = $arguments->{html};
    html {
        show( 'header',
            $author->name . ' > ' . $distvname . ' > ' . $filename );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                        outs ' > ';
                        outs $filename;
                    };

                    a {
                        attr {
                            href => "/raw/~$pauseid/$distvname/$filename" };
                        "See raw file";
                    };
                    if ($html) {
                        div {
                            attr { id => "pod" };
                            outs_raw $html;
                        };
                    } else {
                        pre {$contents};
                    }
                    show('footer');
                };

            };
        };

    }
};

template 'raw' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $distribution = $arguments->{distribution};
    my $filename     = $arguments->{filename};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};
    my $contents     = $arguments->{contents};
    my $html         = $arguments->{html};
    html {
        show( 'header',
            $author->name . ' > ' . $distvname . ' > ' . $filename );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                        outs ' > ';
                        outs $filename;
                    };
                    if ($html) {
                        div {
                            attr { id => "code" };
                            code {
                                outs_raw $html;
                            };
                        };
                    } else {
                        pre {$contents};
                    }
                    div {
                        attr { class => 'download-link' };
                        a {
                            attr {    href => '/download/~'
                                    . $author->pauseid
                                    . "/$distvname/$filename" };
                            "Download as plain text";
                        };
                    };
                    show('footer');
                };

            };
        };

    }
};

template 'opensearch' => sub {
    my $self = shift;
    outs_raw q|<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
<ShortName>minicpan_webserver</ShortName>
<Description>Search minicpan</Description>
<InputEncoding>UTF-8</InputEncoding>
<Image width="16" height="16">data:image/png,%89PNG%0D%0A%1A%0A%00%00%00%0DIHDR%00%00%00%10%00%00%00%10%08%03%00%00%00(-%0FS%00%00%00%01sRGB%00%AE%CE%1C%E9%00%00%003PLTE8%00%00%05%08%04%16%18%15%1E%1F%1D!%22%20%26(%26%2C-%2B130%3B%3D%3AFHELMKXZWegdxyw%84%86%83%9E%A0%9D%CC%CE%CBjq%F6r%00%00%00%01tRNS%00%40%E6%D8f%00%00%00lIDAT%18%D3u%8FY%0E%C20%0C%05%BD%AF)%ED%FDO%0B%85%10%15%04%EF%C7%1A%7B%2C%D9%00%7Fr%C4W%A3u%EB%2B%EFn%E3sAnr1%8E%E11%D4rq%1Bn%9E%CC%8B%15%C5%01%14u%B2%A0%3EmA9K1Z%BD%5C%C6%87%18%B4%18%8A0%A0Q%2B%C3%CC%232%9D%CE%19%E1%3B%3C%E6%E6%CA%BC%C4%A5%BB%C2%84%FC%D7%DBw%7BS%02%E3Ki%23G%00%00%00%00IEND%AEB%60%82</Image>
<Url type="text/html" method="get" template="http://localhost:2963/search/?q={searchTerms}"/>
</OpenSearchDescription>
|;
};

__END__

=head1 NAME

CPAN::Mini::Webserver::Templates - Templates for CPAN::Mini::Webserver

=head1 DESCRIPTION

This module holds the templates, CSS and images for
CPAN::Mini::Webserver.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard.

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.
