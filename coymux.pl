#!/usr/bin/perl -w
use strict;

# -----------------------------------------------------------
#
# coymux.pl		written 1/8/2008
#
#	Operates with the IMPULSE GO proof key as configured 5/5/2006.
#	
#	Key:	Impulse go
#	File: $S.#IMPULSE.DEFAULT
#	Mapgen format:
#		proof^cp^m
#	Textgen format:
#		proof^cp^t
#	Form name: 
#		CP EDITOR N      
#
# -----------------------------------------------------------
#
# Sort and transport Coyote copy
# from the impulsein folder to a more specific folder,
# based on the originating basket in SII. 
# 
# Copy arrives at impulsein via an FTP process on SII.
# Stories are ticketed for this trip by landing 
# in the Coyote IMPULSE GO basket or another basket
# with the same proof key in the HOT PRINTERS list.

# The FTP'd stories are given a number slug of the form FTPxxxx.
# Our eventual job is to extract the original Coyote slug
# from the text of the file.
# We also separate the Coyote header from the body of the story. 

# paths here are relative to publi_hubub. be careful if moving script.

my $platformOS;
$platformOS = "XP";
#$platformOS = "OSX";

my $targetEP;
$targetEP = "\n";       # when target OS = source OS. Not true for Athena-Mac.
#$targetEP = "\x0a";     # Macintosh paragraph ender.

my $watchfolder = "..\\impulsein";
my $donefolder = "..\\impulse_go";

if  ($platformOS eq "OSX") {
	 $watchfolder = "..\/impulsein";
	 $donefolder = "..\/impulse_go";
}

opendir(INDIR, $watchfolder) || die "could not open input directory";

my $nameline;
my $name;
my $prefix;
my $postfix;
my ($headerSlug, $storyHeader, $textSlug, $storyText);

my %basketPath=getConfig();
if (0 == defined($basketPath{"DEFAULT"}) ) {die "COYMUX: No default path in config file"};

print "\n basketpath  \n";
print %basketPath;
print "\n";

$prefix = "$watchfolder\\";
$postfix = "\\";

if ($platformOS eq "OSX") {
$prefix = "$watchfolder\/";
$postfix = "\/";
}

while ($name = readdir(INDIR))
	{
		# iterate through the folder. skip the special directory-path entries.
		# (we call these 'dot dodges' at the end braces below).
		
		if ($name eq ".") {}
		elsif ($name eq "..") {}
		else {
		my $inputfile   = $prefix . $name;
		print "\n inputfile = $inputfile ";
		my $returnvalue;
		
		# Only proceed if the filename starts with capital FTP followed by numerals.

		$_=$inputfile;

		if (m/FTP\d*/) {
		
		open IN,$inputfile;
		binmode IN;

		# new routine for pulling in story. The maps above actually do give us line breaks.
				
		# first line is banner.

		$nameline = <IN>;

		# second line contains full header, even though we think of it as multi-line.

		$nameline = <IN>;
		$storyHeader = getHeader($nameline);		
		my $pdEvents = 0;
		my $mTake = 0;
		my $basket = "DEFAULT";
		$_ = $storyHeader;
		$pdEvents	= m/Author\ *PDEVENTS/;
		$mTake 	= m/No.Spike.n..M/;
		$basket	= $storyHeader;
		$basket	=~ s/.*(Basket..*.Desk).*/$1/g;
		chomp $basket;
		$basket	=~ s/Basket\x20//;
		$basket	=~ s/\x20*Desk.*//;
	
		# from here on out, we should be dealing with the story text.

		$nameline = "";

		# use the Coyote basket in redirecting the file.
		# use the original filename in naming entry 
		# and removing the input file.

		print "earler in main:\n";
		print "\n basketpath  \n";
		print %basketPath;
		print "\n";

		my $path;
		#$path = $basketPath{"DEFAULT"};	# guard against undefined path.
		#$path = $basketPath{$basket};	# real basket, if it's defined.

		if (defined ($basketPath{$basket}))
			{ $path=$basketPath{$basket}; }
		else
			{ $path=$basketPath{"DEFAULT"}; }

		print "in main:\n";
		print "basket = $basket\n";
		print "path = $path\n";

		my $primitiveFileName = $inputfile;
		$primitiveFileName =~ s/.*(FTP.*)/$1/;
		print "\n primitiveFileName = $primitiveFileName \n";

		my $movedFile  = $path . $postfix . $primitiveFileName;

		if ($platformOS eq "OSX") {
		 $movedFile  =~ s/\\/\//;
		}

		print "\n inputfile= $inputfile, movedFile = $movedFile ";
		print "\n not calling rename\n";
		         $returnvalue = rename($inputfile, $movedFile);
		
		print "\n called rename, returnvalue=$returnvalue \n";

		my $cmdLine = "type " . $inputfile . " >" . $movedFile;
		print "\n calling system with: $cmdLine\n";
		system $cmdLine;

		close IN;
                {
                my $cmdLine = "del " . $inputfile;
                if ($platformOS eq "OSX") { $cmdLine = "rm " . $inputfile;}
		print "\n calling system with: $cmdLine\n";
		system $cmdLine;
                }

			} #end if ftp
		} 	# end dot dodges
	}

close (INDIR);

# ===================================================================

sub getHeader {

my	$storyHeader = $_[0];
	$storyHeader =~ s/(.*LN\#  TEXT\-*).*/$1/;
        $_ = $storyHeader;
        my $theresDoubledText = m/Justified.J/;
	return $storyHeader;

} # end getheader

# ===================================================================

sub getConfig

{
open (CONFIG,"COYMUX.cfg") or die "COYMUX: No COYMUX.cfg file";
print "\n";
while (<CONFIG>)
	{
			chomp;
			my ($basket, $path) = split '=';
			print "basket = $basket\n";
			print "path = $path\n";
			$basketPath{$basket}=$path;
	}
close (CONFIG);
return %basketPath;
}

