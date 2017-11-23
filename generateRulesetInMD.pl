#!/usr/bin/perl
use strict;
use Data::Dumper; #library for debugging purpose

require "misc.pl";
#This script is to read in the metadata rulesets in the form of TSV file and convert into JSON format for display on the website
#Written by Jun Fan@EBI

$"=">,<";

unless (scalar @ARGV == 1){
	&usage();
	exit;
}

open TSV, "$ARGV[0]" || die "Could not find the specified tsv file $ARGV[0]\n";
#header line
my $idx = rindex($ARGV[0],".");
my $md_file = substr($ARGV[0],0,$idx).".md";

my %section_info;
$section_info{standard}{display} = "Common";
$section_info{standard}{desc} = "These attributes should be present on every sample record.";
$section_info{organism}{display} = "Animal";
$section_info{organism}{desc} = "An animal sampled for IMAGE. The following attributes are in addition to the attributes listed in the 'Common' section above."; 
$section_info{"specimen from organism"}{display} = "Sample";
$section_info{"specimen from organism"}{desc} = "A piece of tissue taken from an animal. The following attributes are in addition to the attributes listed in the 'Common' section above.";

$section_info{prefix} = "# IMAGE metadata - sample specification\n".

"This document describes the specification for all sample metadata. The [experiment](image_experiment_metadata.md) document will be also available soon. \n\n".
"In the sample context, we consider donor animals and tissue samples at the moment. All samples must be registered in BioSamples at EMBL-EBI as this sample archive has the best support for 'child of' and 'derived from' sample relationships. The NCBI BioSample database is a peer of the EMBL-EBI BioSamples, and they exchange data regularly. IMAGE samples should be registered in the EMBL-EBI BioSamples prior to data submission. This document describes the attributes which must be associated with any BioSamples submission as well as optional fields.\n\n".
"## Sample metadata requirements\n\n".
"Most requirements are laid out like this:\n\n".
"* `attribute name` (*data type*) a brief description\n\n".
"The details of data types can be found [here](image_data_type.md).\n\n".
"[BioSamples](http://www.ebi.ac.uk/biosamples) takes sample records with a set of attributes. Each attribute has a name and a value. It can also have 'Units', or a 'Term Source' and a 'Term Source ID'. The Term Source and ID allow us to refer to entries in other databases or ontologies. This is fully described on the [BioSamples help pages](http://www.ebi.ac.uk/biosamples/help/st_scd.html).\n\n";

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
my @section_names;
#my %section_rules;
while ($line = <TSV>){
	$line_count++;
#	$line=~s/\"//g; #Excel add "" to the strings when exporting as TSV file
	chomp ($line);
	next if ($line=~/^\s*$/); #skip empty line, condition (length $line==0) won't work as \t exists in the line
	next if (substr($line,0,1) eq "#"); #skip lines starting with #
	$line=~s/descendent/descendant/; #make term consistent
#	if ($line=~/\s+conditions:/){
#		my $section = $`;
#		my @conditions = split(",",&trim($'));
#		foreach my $condition(@conditions){
#			my ($term,$value)=split(":",$condition);
#			my @values = split(/\|/,$value);#must use //, not "", for \|
#			if (scalar @values == 1){
#				$section_rules{$section}{$term} = $value;
#			}else{
#				@{$section_rules{$section}{$term}} = @values;
#			}
#		}
#		next;
#	}
	@arr = split("\t",$line);
	my $section = $arr[0];
	push (@section_names,$section) unless (exists $result{$section});
	my %hash;
	for (my $col=1;$col<scalar @arr;$col++){
		my $value = $arr[$col];
		if (length $value>0){ #not empty, only populate the data structure with non-empty values
			if(lc($headers{$col})=~/^valid/){ #in the columns starting with Valid there may be a list of allowed values separated by ,
				#check whether it is a CSV string, if so, separate into array
				#my @tmp = split("\",\"",$value);
				$value=~s/^\"?//;
				$value=~s/\"?$//;
				print "value: <$value>\n";
				$"=">,<";
				
				my @tmp = &parseCSVline($value);
#				print "<@tmp>\n";
				print "found valid in the line: $line\n<@tmp>\n";
				next if (scalar @tmp == 1 && $tmp[0] eq "-");
				for (my $i=0;$i<scalar @tmp;$i++){
					$tmp[$i] = &trim($tmp[$i]); #could use trim() in modules (e.g. use String::Util qw(trim); or use Text::Trim qw(trim);), but they need to install
					if(lc($headers{$col}) eq "valid_terms" || lc($headers{$col}) eq "valid terms"){
						my %abc;
						my $tmp = $tmp[$i];
						$tmp=~s/:/_/;
						if($tmp=~/\(\s?leaf node descendants? only\s?\)/){
							$abc{include_root}=0;
							$abc{leaf_only}=1;
							$tmp = &trim($`);
						}elsif ($tmp =~/^descendants? of /){#default allow_descendants = 1, see https://github.com/FAANG/validate-metadata/blob/master/lib/Bio/Metadata/Rules/PermittedTerm.pm
							$abc{include_root}=0; #default value is 1
							$abc{allow_descendants}=1;
							$tmp = $';
						}elsif($tmp=~/(\w+_\d+)\s*\(?.+?descendants/){
							$abc{include_root}=1;
							$abc{allow_descendants}=1;
							$tmp = $1;
						}else{
							$abc{include_root}=1;
							$abc{allow_descendants}=0;
						}
#						print "remove descendants <$tmp>\n";
						my ($library)=split("_",$tmp);
						$abc{ontology_name} = $library;
						$abc{term} = $tmp;
						$abc{term_iri} = "http://purl.obolibrary.org/obo/$tmp";
						$abc{term_iri} = "http://www.ebi.ac.uk/ols/ontologies/lbo/terms?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2F$tmp" if ($library eq "LBO");
						$tmp[$i]=\%abc;
					}
				}
				$hash{$headers{$col}} = \@tmp;
#				print "$headers{$col}\t<@tmp>\n";
			}elsif(lc($headers{$col}) eq "multiple"){
#				$hash{$headers{$i}} = $value;
				$hash{allow_multiple}=1 if (lc($value) eq "yes");
			}else{
				$value =~ s/\"//g;
				$hash{$headers{$col}} = $value;
			}
		}
	}
	push(@{$result{$arr[0]}{$hash{Required}}},\%hash); #first column in the TSV file indicates the sheet (section)
}

die "No data found in the input TSV file, please check the file. The most possible reason is that the line ending is not recognized." if ($line_count == 0);

my %main;
$main{description}="Validation rules for the IMAGE project.";
$main{name}="IMAGE sample metadata rules";
#if ($json_file=~/experiment/){
#	$main{name}="IMAGE experiment metadata rules";
#}
$main{further_details_iri}="https://github.com/bioinformatics-ptp/IMAGE-metadata/blob/master/README.md";
my @rulesets;
print "The converted MarkDown will be saved in $md_file\n";
open OUT,">$md_file";
print OUT "$section_info{prefix}\n";
my @types = qw/mandatory recommended optional/;
foreach my $sheet(@section_names){
	print OUT "### $section_info{$sheet}{display}\n\n";
	print OUT "$section_info{$sheet}{desc}\n\n" if (exists $section_info{$sheet}{desc});

	foreach my $type(@types){
		next unless (exists $result{$sheet}{$type});

		print OUT ucfirst($type).":\n\n";
		my @tmp = @{$result{$sheet}{$type}};
#  * `Sample name` (*text*) sample names should follow the naming rules listed below. Each name must be unique.
#		print Dumper (\@tmp);
		foreach my $hashref(@tmp){
			my %tmp = %{$hashref};
			print OUT "  * `$tmp{Name}` (*$tmp{Type}*) $tmp{Description}";
			if(exists $tmp{"Valid values"}){
				my @values = @{$tmp{"Valid values"}};
				my @terms;
				my $havingTerm = 0;
				if (exists $tmp{"Valid terms"}){
					@terms = @{$tmp{"Valid terms"}};
					$havingTerm = 1;
				}
				print OUT " Allowed values are:\n";
#				print "having term: $havingTerm\n";
#				print Dumper(\@values);
				for (my $i=0;$i<scalar @values;$i++){
					print OUT "    * ";
					if ($havingTerm == 1 && exists $terms[$i]{term_iri}){
						print OUT "[$values[$i]]($terms[$i]{term_iri})";
					}else{
						print OUT "$values[$i]";
					}
					print OUT "\n";
				}
			}
			#deal with units
#			if(exists $tmp{"Valid units"}){
#				my @units = sort {$a cmp $b} @{$tmp{"Valid units"}};
#				my $len = scalar @units - 1;
#				my $str = " in the units of ";
#				if ($len == 0){
#					$str .= $units[0];
#				} else {
#					my $abc = shift @units;
#					$str = join(",",@units);
#					$str .= " or $abc";
#				} 
#				print OUT "$str";
#			}
			print OUT "\n";
		}
		print OUT "\n";
	}
	my %tmp;
	$tmp{name}=$sheet;
	$tmp{rules}=$result{$sheet};
#	if(exists $section_rules{$sheet}){
#		my @abc = keys %{$section_rules{$sheet}};
#		if (scalar @abc == 1){
#			$tmp{condition}{attribute_value_match} = $section_rules{$sheet};
#		}else{
#			foreach my $abc(@abc){
#				push (@{$tmp{condition}{attribute_value_match}},{$abc=>$section_rules{$sheet}{$abc}});
#			}
#		}
#	}
	push(@rulesets,\%tmp);
}
$main{rule_groups}=\@rulesets;

#convert the data structure into a pretty-formated json
close OUT;

sub usage(){
	print "Usage: perl generateRulesetInMD.pl <rulesets.tsv>\n";
	print "This script convert the rulesets in TSV format (compiled in Excel) into a MarkDown file.\n";
	print "In the TSV file, there is a header line and the first column must be the sheet column\n";
}
