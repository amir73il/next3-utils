#!/usr/bin/perl

use strict;
use warnings;

use Parse::MediaWikiDump;


$| = 1;
print '';

my $file = shift(@ARGV);

my $dump = undef;

$dump = Parse::MediaWikiDump::Pages->new($file);

my $page;
while($page = $dump->next) {
	my $title = $page->title;
	my $text = $page->text;
	$title =~ tr{ }{_};
	print $title, "\n";
	open (MYFILE, '>'.$title);
	print MYFILE $$text;
	close (MYFILE);
};


