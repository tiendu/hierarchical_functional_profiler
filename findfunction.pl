use strict;
use warnings;

my $uniprot_brite_path = shift @ARGV;
my $nr_result_path = shift @ARGV;
my $nr_result_path_cp = $nr_result_path;
$nr_result_path_cp =~ s/.*\///;
my ($file_name, $file_extension) = $nr_result_path_cp =~ /^(.+)\.([^.]+)$/;

open my $uniprot_brite, "<:utf8", $uniprot_brite_path or die;
my %uniprot_brite_hash;
while (<$uniprot_brite>) {
    chomp;
    my @fields = split "\t";
    my $uniprot = $fields[0];
    my $infos = join("\t", @fields[1 .. $#fields]);
    $uniprot_brite_hash{$uniprot} = $infos unless exists $uniprot_brite_hash{$uniprot};
    last if eof $uniprot_brite;
};
close $uniprot_brite;

open my $nr_result, "<:utf8", $nr_result_path or die;
open my $functional_profile, ">:utf8", "function_${file_name}.${file_extension}";
my @records;
while (<$nr_result>) {
    chomp;
    my @fields = split "\t";
    my $uniprot = $1 if $fields[1] =~ m/\|(.+)\|/;
    my $id = $fields[0];
    my $start = $fields[6];
    my $end = $fields[7];
    if ($uniprot_brite_hash{$uniprot}) {
        print $functional_profile "$id\t$start\t$end\t$uniprot_brite_hash{$uniprot}\n";
    };
    last if eof $nr_result;
};
close $nr_result;
close $functional_profile;
