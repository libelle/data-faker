#!/usr/bin/env perl

#
# User Data Maker v. 1.1
#
# Copyright (c) 2008 Samuel Goldstein <samuelg@fogbound.net>, all rights reserved.
# This is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License:
# (http://www.gnu.org/licenses/gpl-2.0.html)
#
# As per the GPL, this software is provided as-is, and with no warranties.
# Please read the text of the license for the full disclaimer.
#
# You must agree to this license before using the module.
#
use Getopt::Long;
use Text::CSV;

$theArgs = ();

# default arguments
$theArgs{'header'} = 'Salutation:First Name:Middle Name:Last Name:Gender:Home Address:Home Address 2:Home City:Home State:Home Zip Code:'.
					 'Vacation Address:Vacation City:Vacation State:Vacation Zip:Email:Home Phone:Work Phone:Marital Status:Age:'.
					 'Platform';
$theArgs{'format'} = 'sa:fn:mn:ln:g:a1:a2:c:s:z:!:a1:c:s:z:e:pne:pwe:'.
					 '{Undisclosed,Single,Married,Divorced,Other,Widowed,Polyamorous,Polygamous,Polyandrous}:[18-105]:'.
					 '[Mac OS,Ubuntu Linux,Redhat Linux,Debian GNU/Linux,Windows XP,Windows Vista,OpenBSD,Minix,Palm OS]';
$theArgs{'count'} = 25;
$theArgs{'csv'} = 0;
$theArgs{'sql'} = 0;
$theArgs{'index'} = 0;
$theArgs{'nerf'} = 0;
$theArgs{'table'} = 'Users';

&usage if (
   ! GetOptions(
        't|header:s'          => \$theArgs{'header'},
        'f|format:s'          => \$theArgs{'format'},
        'm|table:s'           => \$theArgs{'table'},
        'n|number:s'          => \$theArgs{'count'},
        'i|index:s'           => \$theArgs{'index'},
        'x|nerf!'             => \$theArgs{'nerf'},
        'c|csv!'              => \$theArgs{'csv'},
		's|sql!'			  => \$theArgs{'sql'},
        'v|verbose!'          => \$theArgs{'verbose'},
        'h|help'              => \&usage
    ));


if ($theArgs{'verbose'})
   {
   foreach (keys(%theArgs))
      {
      print "$_ = $theArgs{$_}\n";
      }
   }

sub randomIndex()
   {
   ($theMax) = @_;
   return int(rand $theMax);
   }

sub randomInt()
    {
      ($theRange) = @_;
      return int(rand $theRange) + 1;
    }

sub randomIntInRange()
    {
      ($theLowRange,$theHighRange) = @_;
      return $theLowRange + int(rand ($theHighRange - $theLowRange + 1));
    }

#
# This will return a random number between 0 and the specified range.
# The shape of the distribution is determined by the slope of the
# line mapped from 0,$max to $range,$min
sub linearDecayRandomInt()
   {
   ($range, $max, $min) = @_;
   $decay = ($max - $min) / $range;
   $in_range = 0;
	while (! $in_range)
		{
		$x = int(rand $range);
		$y = int(rand $max);
		if ($y < $max - $x * $decay)
			{
			$in_range = 1;
			}
		}
	return $x;
   }

sub randomBool()
    {
     if (rand > 0.5)
        {
          return 1;
        }
     else
         {
           return 0;
         }
    }

sub usage
  {
    print STDERR <<END;
Usage: $0 [OPTIONS]
   -t, --header : header, a colon-delimited list of column headers
   -f, --format : format string, a colon-delimited list of column contents
       data types:
         g - gender
         sa - title/salutation
         fn - first name
         ln - last name
         mi - middle initial
         mn - middle name
         a1 - street address
         a2 - apartment number
         c - city*
         s - state*
         z - zip 5*
         e - email address
         pne - phone (US), no extension
         pwe - phone (US), with extension
         [a,b,c] - one of a, b, or c
         {a,b,c} - one of a, b, or c in decreasing probability
         [x-y] - a number between x and y, inclusive. zero-pad the start range
                 for zero-padded output (e.g., [000-1000] -> 001, [00-1000] -> 01)
         i - index, starting at zero by default
         ^ - single blank space
         /x - lookback and replace with previous item, zero indexed
         ' - literal through the next :
         d - date, optionally specify year and month (eg., d-2010 or d-2010-10)
		 t - timestamp, optionally specify year, month, and day (eg., t-2010 or t-2010-10-31)
		 ! - reset address synch
		 ~ - do not quote this field in database output

         * city, state, and zip will be in agreement to create a valid address
           if you need multiple addresses, use the code ! to reset the
           synch. The reset works on a left-to-right scan of the format string.

		 Individual fields can be composites, for example:
		 fn+^+ln -> "Matthew Jones"
		 c+^+[College,University,Institute] -> "Los Angeles College"
		
		 Other examples:
		 fn:ln:/1+^+[Cars,Trucks,Airplanes,Kitchens]+of+c -> "Sandra","Delgado","Delgado Trucks of Acton"

   -n, --number : number of records to create
   -m, --table  : name for SQL table if generating SQL
   -i, --index  : starting point for index field

   Flags:
  -x, --nerf: nerf email addresses so they are (likely) undeliverable (default false)
  -c, --csv : output CSV format.
  -s, --sql : output as SQL table inserts. Uses the header string
              for column names, table name as provided
  -v, --(no)verbose : verbose mode (default false)

Notes: default output format is tab-delimited, unless
CSV or SQL are specified.
END
    exit 1;
  }

@firstNamesMale= do 'datasources/ordered-male-names.pl';
@firstNamesFemale= do 'datasources/ordered-female-names.pl';
@lastNames = do 'datasources/ordered-surnames.pl';
@streetNames = do 'datasources/ordered-street-names.pl';
@salutationsMale = do 'datasources/weighted-male-salutations.pl';
@salutationsFemale = do 'datasources/weighted-female-salutations.pl';;
@streetDesignations = do 'datasources/street-designations.pl';
%cities = do 'datasources/city-zips.pl';
%states = do 'datasources/state-zips.pl';
@isps = do 'datasources/isps.pl';;

$fnameMaleCount = @firstNamesMale;
$fnameFemaleCount = @firstNamesFemale;
$salutationMaleCount = @salutationsMale;
$salutationFemaleCount = @salutationsFemale;
$lnameCount = @lastNames;
$streetCount = @streetNames;
$streetDCount = @streetDesignations;
@zips = keys(%cities);
$zipCount = @zips;
$ispCount = @isps;

if ($theArgs{'sql'})
	{
	$csv = Text::CSV_PP->new({quote_char=>"'",escape_char=>"'"});
	}
else
	{
	$csv = Text::CSV_PP->new();	
	}
	
#print "$fnameCount $lnameCount $streetCount\n";



@header = split(/\:/,$theArgs{'header'});

if ($theArgs{'csv'})
   {
   $status = $csv->combine (@header);
   print $csv->string();
   }
elsif ($theArgs{'sql'})
   {
   print "-- generated data from $0";
   }
else
   {
   print join("\t",@header);
   }
print "\n";

@outfmt = split(/\:/,$theArgs{'format'});

for ($i=0;$i<$theArgs{'count'};$i++)
    {
    @out = ();
    @outctl = ();
    $zip = '';
    $fname = '';
	$middle = '';
    $lname = '';
    $gender = &randomIndex(2);
    foreach $totaltype (@outfmt)
        {
	    $outval = '';
		if (substr($totaltype,0,1) eq '~')
			{
			$totaltypestr = substr($totaltype,1);
			push (@outctl,'n');
			}
		else
			{
			$totaltypestr = $totaltype;
			push (@outctl,'q');
			}
	    @fmtpieces = split(/\+/,$totaltypestr);
		foreach $type (@fmtpieces)
			{
		    if ($type eq 'i')
				{
		        $outval .= $theArgs{'index'};
				$theArgs{'index'} += 1;
		        }
		    elsif ($type eq '^')
				{
		        $outval .= ' ';
		        }
            elsif ($type eq 'g')
                {
                $outval .= ($gender?"Female":"Male");	
                }
	        elsif ($type eq 'fn')
	            {
				if ($gender == 0)
					{
			        $findex = &linearDecayRandomInt($fnameMaleCount, 100, 20);
			        $fname = $firstNamesMale[$findex];	
					}
				else
					{
				    $findex = &linearDecayRandomInt($fnameFemaleCount, 100, 20);
				    $fname = $firstNamesFemale[$findex];	
					}
				$outval .= $fname;
	            }
	        elsif ($type eq 'mi' || $type eq 'mn')
	            {
				if ($gender == 0)
					{
			        $findex = &linearDecayRandomInt($fnameMaleCount, 100, 20);
			        $middle = $firstNamesMale[$findex];	
					}
				else
					{
				    $findex = &linearDecayRandomInt($fnameFemaleCount, 100, 20);
				    $middle = $firstNamesFemale[$findex];	
					}
				if ($type eq 'mi')
					{
					$outval .= substr($middle,0,1);	
					}
				else
					{
					$outval .= $middle;
					}
	            }
	        elsif ($type eq 'sa')
	            {
				if ($gender == 0)
					{
			        $findex = &randomIndex($salutationMaleCount);
			        $sal = $salutationsMale[$findex];	
					}
				else
					{
				    $findex = &randomIndex($salutationFemaleCount);
				    $sal = $salutationsFemale[$findex];	
					}
				$outval .= $sal;
	            }
	        elsif ($type eq 'ln')
	            {
	            $lindex = &linearDecayRandomInt($lnameCount, 100, 20);
	            $lname = $lastNames[$lindex];
	            $outval .= $lname;
	            }
	        elsif ($type eq 'a1')
	            {
	            $strnum = &randomInt(9999);
	            $strind = &linearDecayRandomInt($streetCount,100, 20);
	            $strdind = &linearDecayRandomInt($streetDCount, 100, 20);
	            $outval .= $strnum.' '.$streetNames[$strind].' '.$streetDesignations[$strdind];
	            }
	        elsif ($type eq 'a2')
	            {
	            $apt = '';
	            if (&randomInt(5) == 1)
	               {
	               if (&randomInt(2) == 1)
	                  {
	                  $apt = '#'.&randomInt(200);
	                  }
	               else
	                  {
	                  $apt = '#'.substr('ABCDEFGHIJ',&randomIndex(10),1);
	                  }
	               }
	            $outval .= $apt;
	            }
	         elsif ($type eq '!')
	            {
	            $zip = '';
	            }
	         elsif ($type eq 'c')
	            {
	            if ($zip == '')
	               {
	               $zip = $zips[&randomIndex($zipCount)];
	               }
	            $outval .= $cities{$zip};
	            }
	         elsif ($type eq 's')
	            {
	            if ($zip == '')
	               {
	               $zip = $zips[&randomIndex($zipCount)];
	               }
	            $outval .= $states{$zip};
	            }
	         elsif ($type eq 'z')
	            {
	            if ($zip == '')
	               {
	               $zip = $zips[&randomIndex($zipCount)];
	               }
	            $outval .= $zip;
	            }
	         elsif ($type eq 'e')
	            {
				$email = '';
				if ($theArgs{'nerf'} == 1)
					{
					$email = 'nerf_';
					}
	            if ($fname ne '' && &randomInt(10) < 5)
	               {
	               $email .= $fname;
	               }
	            elsif ($fname ne '' && $lname ne '' && &randomInt(10) < 5)
	               {
	               $email .= $fname.'.'.$lname;
	               }
	            elsif ($fname ne '' && &randomInt(10) < 5)
	               {
	               $email .= $fname.$middle;
	               }
	            elsif ($lname ne '' && &randomInt(10) < 5)
	               {
	               $email .= $lname;
	               }
	            elsif ($fname ne '' && $lname ne '')
	               {
	               $email .= substr($fname,0,1).$lname;
	               }
	            else
	               {
	               $email .= 'user';
	               for ($j=0;$j<3;$j++)
	                  {
	                  $email .= &randomInt(9);
	                  }
	               }
				$email =~ s/[^\w\d\.\_\%]//g;
	            $email .= '@'. $isps[&randomIndex($ispCount)];
	            $outval .= $email;
	            }
	         elsif ($type eq 'pne' || $type eq 'pwe')
	            {
	            $phone = '';
	            for ($j=0;$j<3;$j++)
	               {
	               $phone .= &randomInt(9);
	               }
	            $phone .= '-';
	            for ($j=0;$j<3;$j++)
	               {
	               $phone .= &randomInt(9);
	               }
	            $phone .= '-';
	            for ($j=0;$j<4;$j++)
	               {
	               $phone .= &randomInt(9);
	               }
	            if ($type eq 'pwe')
	               {
	               $phone .= ' ext. '.&randomInt(9999);
	               }
	            $outval .= $phone;
	            }
	         elsif (substr($type,0,1) eq '[')
	            {
	            if ($type =~ /,/)
	               {
	               # select one of
	               ($optlist = $type) =~ s/[\[\]]//g;
	               @opts = split(/,/,$optlist);
	               $optcount = @opts;
	               $ind = &randomIndex($optcount);
	               $outval .= $opts[$ind];
	               }
	            else
	               {
	               # assume range
	               ($optrange = $type) =~ s/[\[\]]//g;
	               @range = split(/-/,$optrange);
				   if ($range[0]=~/^0/)
						{
						$pad_to = length($range[0]);
						$riir = &randomIntInRange($range[0],$range[1]);
						if ($pad_to > length($riir))
							{
							$outval .= substr('00000000000',0,$pad_to - length($riir)) . $riir;
							}
						else
							{
							$outval .= $riir;
							}
						}
				   else
						{
			            $outval .=  &randomIntInRange($range[0],$range[1]);	
						}
	               }
	            }
			elsif (substr($type,0,1) eq '{')
				{
	               # select one of list, decreasing probability
	               ($optlist = $type) =~ s/[\{\}]//g;
	               @opts = split(/,/,$optlist);
	               $optcount = @opts;
	               $ind = &linearDecayRandomInt($optcount,100,10);
	               $outval .= $opts[$ind];
				}
			elsif (substr($type,0,1) eq '/')
				{
				$lbindex = substr($type,1);
				$outval .= $out[$lbindex];
				}
	         elsif (substr($type,0,1) eq 'd' || substr($type,0,1) eq 't')
	            {
				$fmt = substr($type,1);
				@ctime=localtime(time);
				$year = 0; $month = 0; $day = 0;
				if (substr($fmt,0,1) == '-')
					{
					$fmt = substr($fmt,1);
					($year, $month, $day) = split(/-/, $fmt)
					}
				if ($year == 0)
					{
					$year = 1900 + &randomIntInRange(67,$ctime[5]);
					}
				if ($month == 0)
					{
					$month = &randomIntInRange(1,12);
					}
				if ($day == 0)
					{
					if ($month==9 || $month==4 || $month==6 || $month==11)
						{
						$day = &randomIntInRange(1,30);
						}
					elsif ($month==2)
						{
						$day = &randomIntInRange(1,28);
						}
					else
						{
						$day = &randomIntInRange(1,31);
						}
					}
				if (substr($type,0,1) eq 't')
					{
					$outval .= sprintf("%4d-%02d-%02d %02d:%02d:%02d",
							$year,$month,$day,&randomIntInRange(0,23),
							&randomIntInRange(0,59),&randomIntInRange(0,59));
					}
				else
					{
					$outval .= sprintf("%4d-%02d-%02d",$year,$month,$day);
					}
				}
			elsif (substr($type,0,1) eq '\'')
				{
				# explicitly literal
				$outval .= substr($type,1);
				}
	        else
	            {
				# assumed literal
	            $outval .= $type;
	            }
			}
		push (@out,$outval);
        }
   if ($theArgs{'sql'})
      {
	  print "INSERT INTO ".$theArgs{'table'}." (";
	  $status = $csv->combine (@header);
      print $csv->string();
	  print ") VALUES (";
	  for ($k=0;$k<=$#out;$k++)
		{
		$out[$k] =~ s/\'/\\\'/g;
		if ($out[$k] =~ /[^\d]/ && $outctl[$k] ne 'n')
			{
			$out[$k] = "'".$out[$k]."'";
			}
		}
   	  print join(',',@out);
	  print ");";
      }
   elsif ($theArgs{'csv'})
      {
      $status = $csv->combine (@out);
      print $csv->string();
      }
   else
      {
      print join("\t",@out);
      }
   print "\n";
   }

     
     


