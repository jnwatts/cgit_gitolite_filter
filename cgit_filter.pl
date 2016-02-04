#!/usr/bin/perl

BEGIN {
	$ENV{HOME} = "/srv/gitolite";
	$ENV{CGIT_BIN} = "/opt/cgit/cgit";
	$ENV{GL_BINDIR} = "/opt/gitolite/src";
	$ENV{GL_LIBDIR} = "$ENV{GL_BINDIR}/lib";
	$ENV{GL_USER} = $ENV{"REMOTE_USER"} || "gitweb";
}

unshift @INC, $ENV{GL_LIBDIR};
use lib $ENV{GL_LIBDIR};
use Gitolite::Common;
use Gitolite::Conf::Load;
use Gitolite::Easy;
use HTML::TreeBuilder;

(my $repo)=($ENV{"PATH_INFO"} =~ /^\/?(.*[^\/]+)\.git.*$/);

my $perm = "DENIED"; # Assume denial by default
if ($repo eq "" or $repo eq "/" or repo_missing( $repo )) {
	$perm = "DNE"; # Does not exist, show matching repos
} elsif (can_read($repo)) {
	$perm = "R"; # Repo exists and is readable by the user
}

if ($perm =~ /DNE/) {
    my $doc = HTML::TreeBuilder->new();
    $doc->ignore_ignorable_whitespace(0);
    $doc->no_space_compacting(1);

    my @headers;
    my $headers_complete = 0;

    my @lines = `$ENV{CGIT_BIN}`;
    foreach my $line (@lines) {
        if (!$headers_complete) {
            if ($line eq "\n") {
                $headers_complete = 1;
            } else {
                push(@headers, $line);
            }
        } else {
            $doc->parse($line);
        }
    }
    $doc->eof();

    my $reposection = "";
    my $repo_table = $doc->look_down('_tag', 'table', 'summary', 'repository list');

    foreach my $tr ($repo_table->look_down('_tag', 'tr')) {
        my $td = undef;
        my $repo;
        $td = $tr->look_down('_tag', 'td', sub {
            my $class = $_[0]->attr('class');
            if ($class =~ /(sub|top)level-repo/) {
                return 1;
            }
            return 0;
        });


        if ($td) {
            $a = $td->look_down('_tag', 'a');
            ($repo) = ($a->attr('href') =~ /\.cgi\/([a-zA-Z0-9\.\/_-]+)\.git/);
            (my $reposection) = ($repo =~ /^([a-zA-Z0-9\.\/_-]+)\/[a-zA-Z0-9\._-]+$/);
            my $rs;

            if (not exists $reposections{$reposection}) {
                $rs = {count => 0, name => $reposection};
                $reposections{$reposection} = $rs;
            } else {
                $rs = $reposections{$reposection};
            }

            if (not repo_missing($repo) and can_read($repo)) {
                $rs->{count}++;
            } else {
                $tr->detach();
            }
        }
    }

    my @tds = $repo_table->look_down('_tag', 'td', 'class', 'reposection');
    foreach my $td (@tds) {
        $reposection = $td->as_text;
        my $rs = $reposections{$reposection};
        if ($rs->{count} == 0) {
            my $tr = $td->parent;
            $tr->detach();
        }
    }

    foreach my $h (@headers) {
        print $h;
    }
    print "\n";

    print $doc->as_HTML;
} elsif($perm =~ /R/) {
    system($ENV{CGIT_BIN});
} else {
	print "Content-type: text/html\n\n";
	print "<html>\n";
	print "<body>\n";
	print " <h1>HTTP Status 403 - Access is denied</h1>\n";
	print " You don't have access to repo <b>$repo</b> as <b>$ENV{GL_USER}</b> because $perm\n";
	print "</body>\n";
	print "</html>\n";
}
