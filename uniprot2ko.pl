use strict;

my $brite_json_path = shift @ARGV;
my $uniprot_genes_path = shift @ARGV;
my $genes_ko_path = shift @ARGV;

open my $brite_json, '<:utf8', $brite_json_path or die qq{Can't open $brite_json_path: $!\n};
open my $brite_tsv, '>:utf8', "temp1" or die qq{Can't write to file: $!\n};
my @names;
while (<$brite_json>) {
    next if $. == 4;
    if (m/\A\t{2}"name":"(.+)"/) {
        undef @names;
        $names[0] = $1;
        next;
    };
    if (m/\A\t{3}"name":"(.+)"/) {
        $names[1] = $1;
        next;
    };
    if (m/\A\t{4}"name":"(.+)"/) {
        $names[2] = $1;
        next;
    };
    for my $i (0 .. 2) {
        $names[$i] =~ s/\A[0-9]{5} //;
    };
    $names[2] =~ s/\[(.*?)\]\z//;
    if (m/\A\t{5}"name":"(.+)"/) {
        $names[3] = $1;
        $names[3] =~ m/\A(.+)  |\A(.+); /;
        my $id = $1;
        $id =~ s/ *//;
        while ($names[3] =~ m/$id/) {
            $names[3] =~ s/\A$id[ ;]*//;
        };
        print $brite_tsv join "\t", @names, $id, "\n";
    };
    last if eof $brite_json;
};
close $brite_json;

open $brite_tsv, "<:utf8", "temp1";
open my $brite_tsv_nr, ">:utf8", "temp2" or die qq{Can't write to file: $!\n};
my %hierarchies_id_hash;;
while (<$brite_tsv>) {
    chomp;
    my @fields = split "\t";
    my $id = $fields[-1];
    my $hierarchies = join "\t", @fields[0 .. $#fields-1];
    $hierarchies_id_hash{$id} = [] unless exists $hierarchies_id_hash{$id};
    push @{$hierarchies_id_hash{$id}}, $hierarchies;
    last if eof $brite_tsv;
};
close $brite_tsv;
for my $key (sort keys %hierarchies_id_hash) {
    if (@{$hierarchies_id_hash{$key}} > 1) {
        for (@{$hierarchies_id_hash{$key}}) {
            print $brite_tsv_nr join "\t", $_, $key, "\n" unless (grep /Brite Hierarchies/, $_);
        };
    } 
    elsif (@{$hierarchies_id_hash{$key}} == 1) {
        for (@{$hierarchies_id_hash{$key}}) {
            print $brite_tsv_nr join "\t", $_, $key, "\n" if (grep /Brite Hierarchies/, $_);
        print $brite_tsv_nr join "\t", $_, $key, "\n" unless (grep /Brite Hierarchies/, $_);
        };
    };
};
close $brite_tsv_nr;

open my $uniprot_genes, "<:utf8", $uniprot_genes_path or die qq{Can't open $uniprot_genes_path: $!\n};
open my $genes_ko, "<:utf8", $genes_ko_path or die qq{Can't open $genes_ko_path: $!\n};
open my $uniprot_ko, ">:utf8", "temp3" or die qq{Can't write to file: $!\n};
my %uniprot_genes_ko_hash;
while (<$uniprot_genes>) {
    chomp;
    my ($uniprot, $genes) = split "\t";
    $uniprot_genes_ko_hash{$genes} = $uniprot;
    last if eof $uniprot_genes;
};
close $uniprot_genes;
while (<$genes_ko>) {
    chomp;
    my ($genes, $ko) = split "\t";
    $ko =~ s/ //;
    $uniprot_genes_ko_hash{$genes} .= join "\t", "", $ko if exists $uniprot_genes_ko_hash{$genes};
    last if eof $genes_ko;
};
close $genes_ko;
for (values %uniprot_genes_ko_hash) {
    my ($uniprot, $ko) = split "\t";
    $uniprot =~ s/\Aup://;
    $ko =~ s/\Ako://;
    print $uniprot_ko join "\t", $uniprot, $ko, "\n";
};
close $uniprot_ko;

open $brite_tsv_nr, "<:utf8", "temp2";
open $uniprot_ko, "<:utf8", "temp3";
open my $uniprot_brite, ">:utf8", "uniprot_brite.tsv" or die qq{Can't write to file: $!\n};
my %uniprot_brite_hash;
while (<$uniprot_ko>) {
    chomp;
    my ($uniprot, $ko) = split "\t";
    $uniprot_brite_hash{$ko} = [] unless exists $uniprot_brite_hash{$ko};
    push @{$uniprot_brite_hash{$ko}}, $uniprot;
    last if eof $uniprot_ko;
};
close $uniprot_ko;
print $uniprot_brite join "\t", "UniProt_ID", "KEGG_Orthology_ID", "Level_1", "Level_2", "Level_3", "Level_4", "\n";
while (<$brite_tsv_nr>) {
    chomp;
    my @fields = split "\t";
    my $ko = $fields[-1];
    my $hierarchies = join "\t", @fields[0 .. $#fields-1] if @fields > 1;
    for (@{$uniprot_brite_hash{$ko}}) {
        print $uniprot_brite join "\t", $_, $ko, $hierarchies, "\n";
    };
    last if eof $brite_tsv_nr;
};
close $brite_tsv_nr;
close $uniprot_brite;

unlink "temp1";
unlink "temp2";
unlink "temp3";
