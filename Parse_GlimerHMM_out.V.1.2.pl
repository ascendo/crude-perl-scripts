#!/usr/bin/perl -w
use strict;
use Getopt::Std;
print'
############################################################################################
# This Script is to create Glimmer predicted coding sequences and protein sequenece based  #
# on out put files generated by glimmerHMM program from TIGR.                              #
#                                                                                          #
# Syntax: perl Script_name sequencefile directory                                          #
# Author : Ratnesh Singh                                                                   #
# Contact: ratnesh@hawaii.edu                                                              #
# Version: 1.0                                                                             #
############################################################################################
';
#getopt('sgo');

#Ask for fasta file if not provided at command line.
my ($fasta,$dir,$pattern,%seq);
if(!$ARGV[0]){
	print "\nGive the Name of file containing sequences \n";
	$fasta=<STDIN>;
}
else{
	$fasta=$ARGV[0];
}
open FASTA,"$fasta" or die "cannot open $fasta\n";

if(!$ARGV[1]){$dir=".";}else{$dir=$ARGV[1];}
opendir(DIR,"$dir") or die "Cannot open directory $dir\n";

my $CDS_out="GlimmerHMM_predicted_CDS.fasta";
open CDS,">$CDS_out";
my $pep_out="GlimmerHMM_predicted_protein.fasta";
open PEP,">$pep_out";


#read glimmer out put files as an array in current directory
if(!$ARGV[2]){$pattern="glimmer";}else{$pattern=$ARGV[2];}



my @out_files=grep(/$pattern/,readdir(DIR));
my $number_files= @out_files;

print "files read to be parsed : $number_files\n";

#Reading sequences in memory as hash
print"Reading sequences in memory\n";
$/="\n>";
while(<FASTA>){
	my($header,@sequence)=split(/\n/,$_);
	$header=~s/>//;
	my $sequen= join("",@sequence);
	$sequen=~ s/\s//g;
	$seq{$header}=$sequen;
}


#go through these output files one by one

$/= /^\s+$/;

#dealing each file one by one
foreach my$file(@out_files){
open FILE,"$file" or die " Cannot read file $file";
 my @file_name = split (/\./,$file);
	$file_name[1]=$file;
	$file_name[1]=~ s/(glimmerHMM.)//;
	$file_name[1]=~ s/(.out)//;

print "\nFile being processed: $file";
print "\n\nSorry!!!!!Cannot find sequence: $file_name[1] in sequence file $fasta\n\n" if !exists ($seq{$file_name[1]});
next if !exists($seq{$file_name[1]});	
my$gene_found=0;		
		#Read all the content in one file in array @gene and remove header lines
		my @gene=();
		while(<FILE>){chomp($_);push(@gene,$_);}
		shift(@gene);shift(@gene);shift(@gene);

		#processing each block one by one
		foreach my$gene(@gene){
		my$sequence=my$gene_num=my$strand=my$protein='';
		my@gene_line= split(/\n/,$gene);
			print"*";
			for(my$i=0;$i<=@gene_line-1;$i++){
			chomp($gene_line[$i]);
#			print "\n\n\nline being processed : $gene_line[$i]\n";
			$gene_num=my$exon=$strand=my$ex_type=my$ex_start=my$ex_end=my$ex_len='';
#			print "\nBefore splitting line values: $gene_num,$exon,$strand,$ex_type,$ex_start,$ex_end,$ex_len";
			$gene_line[$i]=~ s/^\s*//;
			($gene_num,$exon,$strand,$ex_type,$ex_start,$ex_end,$ex_len)= split (/\s+/,$gene_line[$i]);
#			print"\nAfter splitting:\n geneNum:$gene_num \n Exon: $exon \n Strand: $strand \n ExType: $ex_type \n ExStart: $ex_start \n ExEnd: $ex_end \n ExLength: $ex_len";
			
			
			my$sequence1= cut_seq($file_name[1],$ex_start,$ex_len);
			$sequence=$sequence.$sequence1;
			}
			$gene_found= @gene; 	
			if($strand eq '-'){
				my$sequence1=reverse($sequence);
				$sequence1=~ tr/ATGCatgc/TACGtacg/;
				$sequence=$sequence1;
			}	
		
			
			my $codon; 

				# Translate each three-base codon into an amino acid, and append to a protein
				for(my $i=0; $i < (length($sequence) - 2) ; $i += 3) { 
 				$codon = substr($sequence,$i,3);
				$protein .= codon2aa($codon);
				} 
			my $pepLen= length($protein);$pepLen=$pepLen-1;
			my $dnaLen= length($sequence);#$dnaLen=$dnaLen-1;
		
			print CDS">"."$file_name[1]"."|"."$gene_num".'|'.'GlimmerHMM_predicted_CDS-'."$gene_num"."[$strand]".'|'."$dnaLen".'_'."nt\n"."$sequence\n";	
			print PEP">"."$file_name[1]"."|"."$gene_num".'|'.'GlimmerHMM_predicted_peptide-'."$gene_num"."[$strand]".'|'."$pepLen".'_'."aa\n"."$protein\n";	

			$pepLen=0;
			$dnaLen=0;
		}	
print"--$gene_found Genes found";			
}	
#print "\nSupercontig_0::: $seq{supercontig_1}\n";

close CDS;
close PEP;
close FASTA;



##################################################################################
# subroutine to cut sequence based on given coordinates

sub cut_seq{
	my($header,$start,$len)=@_;
	$start-=1;
	my$sequence=();
#	print"\nThese values are just before cutting:$header,$start,$len";
	$sequence= substr($seq{$header},$start,$len) if exists $seq{$header};
	print"\nThere is no sequence called: $header\n" if !exists($seq{$header});
	$header=$start=$len=();
#	print"\nThese values are just After cutting:$header,$start,$len";
	return($sequence)if defined $sequence;
}



# # codon2aa 
# # A subroutine to translate a DNA 3-character codon to an amino acid # Version 3, using hash lookup 
sub codon2aa {my($codon) = @_; 
$codon = uc $codon; 
my(%genetic_code) = ( 
'TCA' => 'S', # Serine 
'TCC' => 'S', # Serine 
'TCG' => 'S', # Serine 
'TCT' => 'S', # Serine 
'TTC' => 'F', # Phenylalanine
'TTT' => 'F', # Phenylalanine
'TTA' => 'L', # Leucine 
'TTG' => 'L', # Leucine 
'TAC' => 'Y', # Tyrosine 
'TAT' => 'Y', # Tyrosine
'TAA' => ' ', # Stop
'TAG' => ' ', # Stop
'TGC' => 'C', # Cysteine
'TGT' => 'C', # Cysteine
'TGA' => ' ', # Stop
'TGG' => 'W', # Tryptophan
'CTA' => 'L', # Leucine 
'CTC' => 'L', # Leucine 
'CTG' => 'L', # Leucine 
'CTT' => 'L', # Leucine 
'CCA' => 'P', # Proline 
'CCC' => 'P', # Proline 
'CCG' => 'P', # Proline 
'CCT' => 'P', # Proline 
'CAC' => 'H', # Histidine 
'CAT' => 'H', # Histidine 
'CAA' => 'Q', # Glutamine 
'CAG' => 'Q', # Glutamine 
'CGA' => 'R', # Arginine
'CGC' => 'R', # Arginine
'CGG' => 'R', # Arginine
'CGT' => 'R', # Arginine
'ATA' => 'I', # Isoleucine 
'ATC' => 'I', # Isoleucine 
'ATT' => 'I', # Isoleucine 
'ATG' => 'M', # Methionine 
'ACA' => 'T', # Threonine 
'ACC' => 'T', # Threonine 
'ACG' => 'T', # Threonine 
'ACT' => 'T', # Threonine 
'AAC' => 'N', # Asparagine
'AAT' => 'N', # Asparagine
'AAA' => 'K', # Lysine
'AAG' => 'K', # Lysine
'AGC' => 'S', # Serine 
'AGT' => 'S', # Serine 
'AGA' => 'R', # Arginine
'AGG' => 'R', # Arginine
'GTA' => 'V', # Valine 
'GTC' => 'V', # Valine 
'GTG' => 'V', # Valine 
'GTT' => 'V', # Valine 
'GCA' => 'A', # Alanine 
'GCC' => 'A', # Alanine 
'GCG' => 'A', # Alanine
'GCT' => 'A', # Alanine 
'GAC' => 'D', # Aspartic Acid
'GAT' => 'D', # Aspartic Acid
'GAA' => 'E', # Glutamic Acid 
'GAG' => 'E', # Glutamic Acid 
'GGA' => 'G', # Glycine
'GGC' => 'G', # Glycine
'GGG' => 'G', # Glycine
'GGT' => 'G', # Glycine
); 

if(exists $genetic_code{$codon}) {
return $genetic_code{$codon};
}else{ 

print STDERR "Bad codon \"$codon\"!!\n"; return 'X';}} 

	




