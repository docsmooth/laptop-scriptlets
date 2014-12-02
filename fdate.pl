#!/usr/bin/perl
my $addDays = shift;
my ($second, $minute, $hour, $day, $month, $year, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(time());
my ($fsecond, $fminute, $fhour, $fday, $fmonth, $fyear, $fdayOfWeek, $fdayOfYear, $fdaylightSavings) = localtime(time() + $addDays*24*60*60);

#fix 0 = 1 values, and "0 = 1900" problem:
$month++; 
$fmonth++;
$year+=1900; 
$fyear+=1900;

print "today is:             $month/$day/$year\n";
print "$addDays day from today is: $fmonth/$fday/$fyear\n";
