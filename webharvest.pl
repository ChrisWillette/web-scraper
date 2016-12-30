#!/usr/bin/perl
use strict;

my $site="http://www.nytimes.com";

my @image_urls;
my @link_urls;

open (my $fh, "curl $site |") or die "$!\n";

for (<$fh>) {
    
  while (m/<\s*img\s+src\s*=\s*"([^"]*)"/gi) {
	 my $url = $1;
	 push @image_urls, $url;
  }
# while (m/<\s*a\s+href\s*=\s*"([^"]*)"/gi){
 while (m/<\s*a\s+href\s*=\s*\"([^\"]*)\"/gi) { # XXX
	 my $url = $1;
	 $url = $site . $url unless $url =~ /^https?:/i;
	 if ($url =~ /\.(png|bmp|jp?g|gif)$/) {
	    push @image_urls, $url;
	 } else {
 	    push @link_urls, $url;
	 }
  }
}

close $fh;

my $THUMBDIR = "thumbs";
mkdir $THUMBDIR unless -d $THUMBDIR;

my $COLS = 8;
my $N = 0;

print <<"EOF";
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Web Harvest ($site)</title>
 <style>
    body {  /* CSS3 styles */
      color: DarkSlateBlue;
      background-color: #88CCFF;
      font-family: Georgia, serif;
    }
    table {
      border-collapse: collapse;
    }
    td {
      border: 1px solid blue;
    }
  </style> 
 </head>
  <body>
    <h2>Web Harvest ($site)</h2>
    <h3> Images Harvested </h3>
  <table>
EOF

for (@image_urls) {

    my $url = $_;
    $url = "$site/" . $url unless $url =~ /^https?:/;

    if (m{.*/(.*)\..*$}) {
	my $thumb = "$THUMBDIR/$1.png";
	
	unless (-e $thumb) {
	    my $cmd  = "curl '$_' | convert - -resize 50x50 '$thumb'";
	    print STDERR "$cmd\n";
	    next unless system($cmd) == 0;
	}

	print "   <tr>\n" if $N % $COLS == 0;
	print "   <td><a href=\"$url\"><img src=\"$thumb\" /></td>\n";
 
	$N++;
	print "   </tr>\n" if $N % $COLS == 0;
    }
}

print "   </tr>\n" if $N % $COLS != 0;

print<<"EOF";
   </table>
   <h3> Links Harvested </h3>
   <table>
EOF
 
my $counter = 0;
for (@link_urls){
    print " <tr><td><a href=\"@link_urls[$counter]\">@link_urls[$counter]</a></td></tr>\n";
    $counter++;
#i know i shouldn't need this indexing business, but it kept creating
#one GIANT link without it.
 }

print<<"EOF";
</table>
<h3> Unique Links </h3>
<table>
EOF


my %sites;
for (@link_urls) {
    $sites{$1} = 1 if m{https?://([^/\%\:]*)}i;

}

   print "<tr><td><a href=\"http://$_\">$_</a></td></tr>\n" foreach (keys%sites); 

print<<"EOF";
</table>
<hr>
EOF


my $datestring = gmtime();
print "<i> $datestring GMT</i><br>";


print<<"EOF";
<i>Chris Willette</i>
  </body>
</html>
EOF




