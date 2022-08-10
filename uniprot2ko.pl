use strict;

my $brite_json_path = shift @ARGV;
my $uniprot_to_genes_path = shift @ARGV;
my $genes_to_ko_path = shift @ARGV;

open my $brite_json, "<:utf8", $brite_json_path or die qq{Can't open $brite_json_path: $!\n};
open my $brite_tsv, ">:utf8", "temp1" or die qq{Can't write to file: $!\n};
my @records;
while (<$brite_json>) {
    next if $. == 4;
    if (m/\A\t{2}"name":"(.+)"/) {
        undef @records;
        $records[0] = $1;
        next;
    };
    if (m/\A\t{3}"name":"(.+)"/) {
        $records[1] = $1;
        next;
    };
    if (m/\A\t{4}"name":"(.+)"/) {
        $records[2] = $1;
        next;
    };
    for my $i (0 .. 2) {
        $records[$i] =~ s/\A[0-9]{5} //;
    };
    $records[2] =~ s/\[(.*?)\]\z//;
    if (m/\A\t{5}"name":"(.+)"/) {
        $records[3] = $1;
        $records[3] =~ m/\A(.+)  |\A(.+); /;
        my $id = $1;
        $id =~ s/ *//;
        while ($records[3] =~ m/$id/) {
            $records[3] =~ s/\A$id[ ;]*//;
        };
        print $brite_tsv join "\t", @records, $id, "\n";
    };
    last if eof $brite_json;
};
close $brite_json;

open $brite_tsv, "<:utf8", "temp1";
open my $nr_brite_tsv, ">:utf8", "temp2" or die qq{Can't write to file: $!\n};
my %id_hierarchies_hash;;
while (<$brite_tsv>) {
    chomp;
    my @fields = split "\t";
    my $id = $fields[-1];
    my $hierarchies = join "\t", @fields[0 .. $#fields-1];
    $id_hierarchies_hash{$id} = [] unless exists $id_hierarchies_hash{$id};
    push @{$id_hierarchies_hash{$id}}, $hierarchies;
    last if eof $brite_tsv;
};
close $brite_tsv;
for my $key (sort keys %id_hierarchies_hash) {
    if (@{$id_hierarchies_hash{$key}} > 1) {
        for (@{$id_hierarchies_hash{$key}}) {
            print $nr_brite_tsv join "\t", $_, $key, "\n" unless (grep /Brite Hierarchies/, $_);
        };
    } 
    elsif (@{$id_hierarchies_hash{$key}} == 1) {
        for (@{$id_hierarchies_hash{$key}}) {
            print $nr_brite_tsv join "\t", $_, $key, "\n" if (grep /Brite Hierarchies/, $_);
        print $nr_brite_tsv join "\t", $_, $key, "\n" unless (grep /Brite Hierarchies/, $_);
        };
    };
};
close $nr_brite_tsv;

open my $uniprot_to_genes, "<:utf8", $uniprot_to_genes_path or die qq{Can't open $uniprot_to_genes_path: $!\n};
open my $genes_to_ko, "<:utf8", $genes_to_ko_path or die qq{Can't open $genes_to_ko_path: $!\n};
open my $uniprot_to_ko, ">:utf8", "temp3" or die qq{Can't write to file: $!\n};
my %uniprot_to_genes_to_ko_hash;
while (<$uniprot_to_genes>) {
    chomp;
    my ($uniprot, $genes) = split "\t";
    $uniprot_to_genes_to_ko_hash{$genes} = $uniprot;
    last if eof $uniprot_to_genes;
};
close $uniprot_to_genes;
while (<$genes_to_ko>) {
    chomp;
    my ($genes, $ko) = split "\t";
    $ko =~ s/ //;
    $uniprot_to_genes_to_ko_hash{$genes} .= join "\t", "", $ko if exists $uniprot_to_genes_to_ko_hash{$genes};
    last if eof $genes_to_ko;
};
close $genes_to_ko;
for (values %uniprot_to_genes_to_ko_hash) {
    my ($uniprot, $ko) = split "\t";
    $uniprot =~ s/\Aup://;
    $ko =~ s/\Ako://;
    print $uniprot_to_ko join("\t", $uniprot, $ko, "\n");
};
close $uniprot_to_ko;

open $nr_brite_tsv, "<:utf8", "temp2";
open $uniprot_to_ko, "<:utf8", "temp3";
open my $uniprot_brite, ">:utf8", "uniprot_brite.tsv" or die qq{Can't write to file: $!\n};
my %uniprot_brite_hash;
while (<$uniprot_to_ko>) {
    chomp;
    my ($uniprot, $ko) = split "\t";
    $uniprot_brite_hash{$ko} = [] unless exists $uniprot_brite_hash{$ko};
    push @{$uniprot_brite_hash{$ko}}, $uniprot;
    last if eof $uniprot_to_ko;
};
close $uniprot_to_ko;
while (<$nr_brite_tsv>) {
    chomp;
    my @fields = split "\t";
    my $ko = $fields[-1];
    my $hierarchies = join "\t", @fields[0 .. $#fields-1] if @fields > 1;
    for (@{$uniprot_brite_hash{$ko}}) {
        print $uniprot_brite join "\t", $_, $ko, $hierarchies, "\n";
    };
    last if eof $nr_brite_tsv;
};
close $nr_brite_tsv;
close $uniprot_brite;

unlink "temp1";
unlink "temp2";
unlink "temp3";
