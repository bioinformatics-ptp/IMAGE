#!/usr/bin/perl
use JSON; #library for JSON IO
use strict;
use Data::Dumper; #library for debugging purpose

unless (scalar @ARGV == 1){
	&usage();
	exit;
}

open TSV, "$ARGV[0]" || die "Could not find the specified tsv file $ARGV[0]\n";
#the one would be used in Excel for data validation (added by a separate VBA code)
my $line = <TSV>;
chomp ($line);
#print "$line\n";

my @arr = split("\t",$line);
my %headers;
for (my $i=0;$i<scalar @arr;$i++){
	$headers{$i} = $arr[$i];
}

my %result;
while ($line = <TSV>){
	chomp ($line);
	next if ($line=~/^\s*$/); #length $line won't work as \t exists in the line
	next if (substr($line,0,1) eq "#");
	@arr = split("\t",$line);
	my %hash;
	for (my $i=1;$i<scalar @arr;$i++){
		my $value = $arr[$i];
		$hash{$headers{$i}} = $value if (length $value>0);
	}

	push(@{$result{$arr[0]}},\%hash)
}

#convert the data structure into a pretty-formated json
my $json = to_json(\%result,{pretty=>1});
open JSON_OUT,">IMAGE_ruleset.json";
print JSON_OUT "$json\n";
close JSON_OUT;

sub usage(){
	print "Usage: perl generateRulesetInJSON.pl <rulesets.tsv>\n";
	print "This script convert the rulesets in TSV format (compiled in Excel) into a JSON file.\n";
	print "In the TSV file, there is a header line and the first column must be the sheet column\n";
}
sub testReadInJSON(){
	open IN, "generated.json";
	my $json = "";
	while (my $line=<IN>){
		$json .= $line;
	}
	my $text = decode_json ($json);
	print Dumper($text);
}

sub testWriteToJSON(){
	my @elmts;
	for (my $i=1;$i<4;$i++){
		my %hash;
		$hash{id} = $i;
		$hash{value} = "$i * $i equals ".($i*$i);
		my @a;
		for (my $j=0;$j<$i;$j++){
			push(@a,$j);
		}
		$hash{arr} = \@a;
		push (@elmts,\%hash);
	}
#	my $json = JSON->new;
	
	my $str = to_json(\@elmts,{pretty=>1});
	print "$str\n\n";
#	print Dumper(\@elmts);
#$json_text = JSON->new->utf8->encode($perl_scalar)
#$json = $json->pretty([$enable])
	my $json_str = encode_json (\@elmts);
	print "$json_str\n";
}
