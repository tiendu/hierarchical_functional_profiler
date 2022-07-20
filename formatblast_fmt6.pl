use strict;

my $result_path = shift @ARGV;

open my $result, "<:utf8", $result_path or die qq{Can't open $result_path: $!\n};
my %infos_hash;
while (<$result>) {
    chomp;
    my @fields = split "\t";
    my $id = $fields[0];
    my $uniprot_id = $1 if $fields[1] =~ m/\|(.+)\|/;
    my $ident = $fields[2];
    my $len = $fields[3];
    my $qstart;
    my $qend;
    my $tstart = $fields[-4];
    my $tend = $fields[-3];
    my $sense;
    if ($fields[6] > $fields[7]) {
        $qstart = $fields[7];
        $qend = $fields[6];
        $sense = "-";
    } 
    else {
        $qstart = $fields[6];
        $qend = $fields[7];
        $sense = "+"
    };
    my $evalue = $fields[-2];
    my $bit = $fields[-1];
    my @info = ([$uniprot_id, $sense, $len, $ident, $evalue, $bit, $qstart, $qend, $tstart, $tend]);
#     filtering follows this guide: 10.1002/0471250953.bi0301s42
    if ($ident > 20 && $evalue < 1.0e-3 && $bit > 50) {
        $infos_hash{$id} = [] unless exists $infos_hash{$id};
        push @{$infos_hash{$id}}, @info;
    };
};
close $result;

open my $result_nr, ">:utf8", "temp4";
my %id_pos_hash;
for my $id (sort keys %infos_hash) {
    my @array = @{$infos_hash{$id}};
    my @pos;
    foreach (@array) {push @pos, [@$_[-4], @$_[-3]];};
    my @removal;
    for my $item1 (@pos) {
        for my $item2 (@pos) {
            unless ($item1 == $item2) {
                my ($s1, $e1) = @$item1;
                my ($s2, $e2) = @$item2;
                if ($s1 >= $s2 && $e1 <= $e2) {
                    push @removal, $item1;
                };
            };
        };
    };
    my @unique = do {my %seen; grep {!$seen{$_}++} @removal};
    foreach (@unique) {my $index = 0; $index++ until $pos[$index] == $_; splice(@pos, $index, 1);};
    foreach (@pos) {
        $id_pos_hash{$id} = [] unless exists $id_pos_hash{$id};
        push @{$id_pos_hash{$id}}, @pos;
    };
};
print $result_nr "Sequence_ID\tUniProt_ID\tLen\tIdent\tEvalue\tBit\tQStart\tQEnd\tTStart\tTEnd\n";
my @records;
for my $id (sort keys %id_pos_hash) { 
    my @array = @{$id_pos_hash{$id}};
    for my $item1 (@array) {
        my ($s1, $e1) = @$item1;
        for my $item2 (@{$infos_hash{$id}}) {
            my ($s2, $e2) = (@$item2[-4], @$item2[-3]);
            if ($s1 == $s2 && $e1 == $e2) {
                if (@$item2[1] eq "+") {
                    push @records, join("\t", $id, @$item2[0], @$item2[2 .. 9], "\n");
                } elsif (@$item2[1] eq "-") {
                    push @records, join("\t", $id, @$item2[0], @$item2[2 .. 5], @$item2[7], @$item2[6], @$item2[8], @$item2[9], "\n");
                };
            };
        };
    };
};
my @uniq_records = do {my %seen; grep {!$seen{$_}++} @records};
foreach (@uniq_records) {
    print $result_nr $_;
};
close $result_nr;
