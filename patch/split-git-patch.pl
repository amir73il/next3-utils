#!/usr/bin/perl -w
# (c) Erez Zadok, 2009
# Usage: git diff [args] > large.patch
#        split-git-patch.pl large.patch

$debug = 1;
$openfile = 0;

while (($line = <>)) {
    if ($line =~ /^diff --git a\/(\S+)/) {
	$file = $1;
	$file =~ tr/[a-zA-Z0-9_\-\.]/_/c;
	print "SPLIT-GIT-PATCH : $1 : $file\n" if $debug;
	close(FILE) if ($openfile);
	open(FILE, "> $file") || die "$file:$!";
	$openfile = 1;
    }
    printf(FILE "%s", $line);
    next;
}
close(FILE);
