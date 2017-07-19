#!/usr/bin/perl
use JSON; #library for JSON IO
use strict;
use Data::Dumper; #library for debugging purpose

#This script is to read in the metadata rulesets in the form of TSV file and convert into JSON format for display on the website
#Written by Jun Fan@EBI

unless (scalar @ARGV == 1){
	&usage();
	exit;
}

open TSV, "$ARGV[0]" || die "Could not find the specified tsv file $ARGV[0]\n";
#header line
my $line = <TSV>;
chomp ($line);
print "The header line is $line\n";
#the headers will be used as keys in the JSON, will be matched to values by the column number
my @arr = split("\t",$line);
my %headers;
for (my $i=0;$i<scalar @arr;$i++){
	$headers{$i} = $arr[$i];
}

my $line_count = 0;
my %result;
while ($line = <TSV>){
	$line_count++;
	$line=~s/\"//g; #Excel add "" to the strings when exporting as TSV file
	chomp ($line);
	next if ($line=~/^\s*$/); #skip empty line, condition (length $line==0) won't work as \t exists in the line
	next if (substr($line,0,1) eq "#"); #skip lines starting with #
	@arr = split("\t",$line);
	my %hash;
	for (my $i=1;$i<scalar @arr;$i++){
		my $value = $arr[$i];
		if (length $value>0){ #not empty, only populate the data structure with non-empty values
			if(lc($headers{$i})=~/^valid/){ #in the columns starting with Valid there may be a list of allowed values separated by ,
				#check whether it is a CSV string, if so, separate into array
				my @tmp = split(",",$value);
				if (scalar @tmp==1){ #no , found, i.e. single value
					$hash{$headers{$i}} = $value ;
				}else{
					for (my $i=0;$i<scalar @tmp;$i++){
						$tmp[$i] = trim($tmp[$i]); #could use trim() in modules (e.g. use String::Util qw(trim); or use Text::Trim qw(trim);), but they need to install
					}
					$hash{$headers{$i}} = \@tmp;
				}
			}else{
				$hash{$headers{$i}} = $value;
			}
		}
	}
	push(@{$result{$arr[0]}},\%hash); #first column in the TSV file indicates the sheet (section)
}

die "No data found in the input TSV file, please check the file. The most possible reason is that the line ending is not recognized." if ($line_count == 0);

#convert the data structure into a pretty-formated json
my $json = to_json(\%result,{pretty=>1});
open JSON_OUT,">IMAGE_ruleset.json";
print JSON_OUT "$json\n";
close JSON_OUT;

sub trim(){
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s;
}

sub usage(){
	print "Usage: perl generateRulesetInJSON.pl <rulesets.tsv>\n";
	print "This script convert the rulesets in TSV format (compiled in Excel) into a JSON file.\n";
	print "In the TSV file, there is a header line and the first column must be the sheet column\n";
}
