#!/usr/bin/perl -w
use strict;

# -----------------------------------------------------------
#
# camPhotoNightly.pl		written 5/21/2008
#
#
# -----------------------------------------------------------
#
# Examine the CamPhotoExp folder on a nightly basis,
# deleting photos that are apparently dailies,
# and moving presumed advance photos to Done & Sent. 
# 
# What makes a photo a daily?
#	- Today's date is found in the slug: M0531B1.1B0531A.JPG on May 31, for example.
# 	- It has an M (metro) or S (sports) topic code: M0531B1.WEBONLY.JPG, for example.
#	- It has an A- or B-section print slug: 1B0531A.JPG, for example.
#

my $platformOS;
#$platformOS = "XP";
$platformOS = "OSX";

my $targetEP;
$targetEP = "\n";       # when target OS = source OS. Not true for Athena-Mac.
#$targetEP = "\x0a";     # Macintosh paragraph ender.

my $watchfolder = ".\\CamPhotoExp";
my $donefolder = ".\\CamPhotoExp\\donesent";

if  ($platformOS eq "OSX") {
	 $watchfolder = "CamPhotoExp";
	 $donefolder = ".\/CamPhotoExp/donesent";
}

my $daystring;
{
my @timenum = localtime;
my $monthnum = $timenum[4] + 1;
my $daynum = $timenum[3];
$daystring = sprintf("%2d%2d", $monthnum, $daynum);
$daystring =~ s/\x20/0/;
#print "daystring = $daystring \n";
}

close STDOUT;
open STDOUT, ">cpe_clean_log.txt"; 

opendir(INDIR, $watchfolder) || die "could not open input directory";

my $nameline;
my $name;
my $prefix;
my $postfix;

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
		
		# next block equates any non-JPG file with the dot-dodges.			
		# that way we skip any folders, system-related files, etc.
		{
		my $testname1 = uc($name);
		my $testname2 = uc($name);
		$testname2 =~ s/JPG//;
		if ($testname1 eq $testname2) {$name = "..";}
		#print "testname1= $testname1 \t testname2= $testname2 \tname = $name \n";
		}
		$name = skipNSadvance($name, $daystring);

		if ($name eq ".") {}
		elsif ($name eq "..") {}
		else {
		my $inputfile   = $prefix . $name;
		#print "\n inputfile = $inputfile \n";
		my $returnvalue;
		
		# Only proceed if the filename starts with capital FTP followed by numerals.

		$_=$inputfile;
		
		# old if ftp.
			{
				my $goner = OKtoDelete($name,$daystring);
				if ($goner)
				{
					print "$name is a goner \n";
					unlink $inputfile;
				}	# end if goner
				else
				{
					print "$name is done and sent \n";
				}	# end else goner.	
	

			} #end if ftp
		} 	# end dot dodges
	}
		# any jpg not unlinked can now be moved en masse.
		my $command;
		if ($platformOS eq "OSX")
			{ $command = 'cp ' . $watchfolder . '/*.jpg ' . $donefolder; }
		else
			{ $command = 'copy ' . $watchfolder . '\*.jpg ' . $donefolder; }
		# print "command = $command \n";
		system($command);
		$command =~ s/jpg/JPG/;
		system($command);

		if ($platformOS eq "OSX")
			{ $command = 'rm ' . $watchfolder . '/*.jpg'; }
		else
			{ $command = 'del ' . $watchfolder . '\*.jpg'; }
		# print "command = $command \n";
		system($command);
		$command =~ s/jpg/JPG/;
		system($command);

close (INDIR);

# ===================================================================

sub OKtoDelete
{
	$_ = my $filename = $_[0];
	my $datestring = $_[1];

	my $goner = 0;

	if (m/$datestring/) {$goner++;}

	if (m/^\d{1,2}[AB]\d{4}/) 	# print-only slug, A or B section.
		{$goner++; }
	if (m/\d*?\.\d{1,2}[AB]\d{4}/) 	# print-and-web slug, A or B section.
		{$goner++; }
	if (m/^[MS]\d{4}[A-Z]{1,2}\d*?/)	# web slug Metro or Sports.	
		{$goner++; }
	if ($goner > 0) { $goner = 1;}
	return $goner;
}

# ===================================================================

# skipNSadvance -- return a '..' in place of the name
# if photo is an advance for Sports or News (1A/1B).
# the '..' is a signal to ignore the file. It won't go to Done & Sent, 
# and it won't get tossed either.

sub skipNSadvance
{
	print "skipNSadvance called\n";
	my $daystring = $_[1];
	$_ =  my $name = $_[0];
	print "skipNSadvance: name= $name\n";
	print "skipNSadvance: daystring = $daystring \n";
	if (m/$daystring/)				# is a plain old daily?
		{
			return $name;			# return unchanged.
		}
	if (m/[MSB]\d{4}[A-Z]/)			# is it metro or sports or biz with any other date?
		{
			print "skipNSadvance: got M, S or B\n";
			my $monworkname = my $dayworkname = $name;
			my $monworktom  = my $dayworktom  = $daystring;

			print "skipNSadvance: monworkname = $monworkname\n";
			print "skipNSadvance: monworktom = $monworktom\n";
			
			$monworkname =~ s/.*?(\d\d)\d\d.*/$1/;
			$dayworkname =~ s/.*?\d\d(\d\d).*/$1/;
			
			$monworktom  =~ s/(\d\d)\d\d.*/$1/;
			$dayworktom  =~ s/\d\d(\d\d).*/$1/;

			print "2. skipNSadvance: monworkname = $monworkname\n";
			print "2. skipNSadvance: monworktom = $monworktom\n";
			print "2. skipNSadvance: dayworkname = $dayworkname\n";
			print "2. skipNSadvance: dayworktom = $dayworktom\n";

			if (($monworkname + 6 ) < ($monworktom))	# dodge for date extending into next year.
				{ $monworkname += 12; }
			
			my $namework = $monworkname * 31 + $dayworkname;
			my $tomwork  = $monworktom * 31  + $dayworktom;
			print "skipNSadvance: namework = $namework \n";
			print "skipNSadvance: tomwork = $tomwork \n";
			
			if ($namework > $tomwork)	# publishes after tomorrow
				{
					print "$name ignored \n";
					return '..';		# skip it.
				}
			else
				{
					print "$name left alone\n";
					return $name;		# handle as daily or older.
				}
		} # end if [MS]nnnn .
	else 
		{
			return $name;			# any other photo.
		}
}








		
