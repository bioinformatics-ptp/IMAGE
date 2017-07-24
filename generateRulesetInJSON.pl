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
	for (my $col=1;$col<scalar @arr;$col++){
		my $value = $arr[$col];
		if (length $value>0){ #not empty, only populate the data structure with non-empty values
			if(lc($headers{$col})=~/^valid/){ #in the columns starting with Valid there may be a list of allowed values separated by ,
				#check whether it is a CSV string, if so, separate into array
				my @tmp = split(",",$value);
				for (my $i=0;$i<scalar @tmp;$i++){
					$tmp[$i] = trim($tmp[$i]); #could use trim() in modules (e.g. use String::Util qw(trim); or use Text::Trim qw(trim);), but they need to install
					if(lc($headers{$col}) eq "valid_terms"){
						print "$tmp[$i]\t";
						my %abc;
						my $tmp = $tmp[$i];
						$tmp=~s/:/_/;
						if ($tmp =~/^descendants? of /){#default allow_descendants = 1, see https://github.com/FAANG/validate-metadata/blob/master/lib/Bio/Metadata/Rules/PermittedTerm.pm
							$tmp = $';
						}elsif($tmp=~/(\w+_\d+)\s*\(?.+?descendants/){
							$tmp = $1;
						}else{
							$abc{allow_descendants}=0;
						}
						print "remove descendants <$tmp>\n";
						my ($library)=split("_",$tmp);
						$abc{ontology_name} = $library;
						$abc{term_iri} = "http://purl.obolibrary.org/obo/$tmp";
						$tmp[$i]=\%abc;
					}
				}
				$hash{$headers{$col}} = \@tmp;
				print "\n";
			}elsif(lc($headers{$col}) eq "multiple"){
#				$hash{$headers{$i}} = $value;
				$hash{allow_multiple}=1 if (lc($value) eq "yes");
			}else{
				$hash{$headers{$col}} = $value;
			}
		}
	}
	push(@{$result{$arr[0]}},\%hash); #first column in the TSV file indicates the sheet (section)
}

die "No data found in the input TSV file, please check the file. The most possible reason is that the line ending is not recognized." if ($line_count == 0);

my %main;
$main{description}="Validation rules for the IMAGE project.";
$main{name}="IMAGE sample metadata rules";
$main{further_details_iri}="https://github.com/bioinformatics-ptp/IMAGE-metadata/blob/master/README.md";
my @rulesets;
foreach my $sheet(keys %result){
	my %tmp;
	$tmp{name}=$sheet;
	$tmp{rules}=$result{$sheet};
	push(@rulesets,\%tmp);
}
$main{rule_groups}=\@rulesets;

#convert the data structure into a pretty-formated json
my $json = to_json(\%main,{pretty=>1});
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
