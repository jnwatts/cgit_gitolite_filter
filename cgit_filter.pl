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

(my $repo)=($ENV{"PATH_INFO"} =~ /^\/?(.*[^\/]+)\.git.*$/);

my $perm = "DENIED"; # Assume denial by default
if ($repo eq "" || repo_missing( $repo )) {
	$perm = "DNE"; # Does not exist, show matching repos
} elsif (can_read($repo)) {
	$perm = "R"; # Repo exists and is readable by the user
}

if ($perm !~ /DENIED/) {
	system("$ENV{CGIT_BIN}");
} else {
	print "Content-type: text/html\n\n";
	print "<html>\n";
	print "<body>\n";
	print " <h1>HTTP Status 403 - Access is denied</h1>\n";
	print " You don't have access to repo <b>$repo</b> as <b>$ENV{GL_USER}</b> because $perm\n";
	print "</body>\n";
	print "</html>\n";
}
