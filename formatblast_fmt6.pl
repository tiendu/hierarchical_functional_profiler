use strict;
use feature 'say';

my $resultPath = shift @ARGV;

open my $result, "<:utf8", $resultPath or die qq{Can't open $resultPath: $!\n};
my %infosHash;
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
        $infosHash{$id} = [] unless exists $infosHash{$id};
        push @{$infosHash{$id}}, @info;
    };
};
close $result;

open my $resultnr, ">:utf8", "filtered_result.tsv";
print $resultnr "Sequence_ID\tUniProt_ID\tLen\tIdent\tEvalue\tBit\tQStart\tQEnd\tTStart\tTEnd\n";
my %idposHash;
for my $id (sort keys %infosHash) {
    my @array = @{$infosHash{$id}};
    my @pos_p;
    my @pos_n;
    for my $item (@array) {
        if (@$item[1] eq "+") {
            push @pos_p, [@$item[-4], @$item[-3]];
        } elsif (@$item[1] eq "-") {
            push @pos_n, [@$item[-4], @$item[-3]];
        };
    };
    my @pos_p_u = uniq(@pos_p);
    my @removal_p;    
    for my $item1 (@pos_p_u) {
        for my $item2 (@pos_p_u) {
            unless ($item1 == $item2) {
                my ($s1, $e1) = @$item1;
                my ($s2, $e2) = @$item2;
                if ($s1 == $s2 && $e1 < $e2) { # remove only genes with the same starting position and have less length
                    push @removal_p, $item2;
                };
            };
        };
    };
    my @removal_p_u = uniq(@removal_p);
    for (@removal_p_u) {
        my $index = 0;
        $index++ until $pos_p_u[$index] == $_;
        splice(@pos_p_u, $index, 1);
    };
    
    my @pos_n_u = uniq(@pos_n);
    my @removal_n;
    for my $item1 (@pos_n_u) {
        for my $item2 (@pos_n_u) {
            unless ($item1 == $item2) {
                my ($s1, $e1) = @$item1;
                my ($s2, $e2) = @$item2;
                if ($s1 >= $s2 && $e1 <= $e2) {
                    push @removal_n, $item2;
                };
            };
        };
    };
    my @removal_n_u = uniq(@removal_n);
    for (@removal_n_u) {
        my $index = 0;
        $index++ until $pos_n_u[$index] == $_;
        splice(@pos_n_u, $index, 1);
    };
    for my $item1 (@pos_p_u) {
        for my $item2 (@array) {
            my ($s1, $e1) = @$item1;
            my ($s2, $e2) = (@$item2[-4], @$item2[-3]);
            if  (@$item2[1] eq "+") {
                if ($s1 == $s2 && $e1 == $e2) {
                    print $resultnr join "\t", $id, @$item2[0], @$item2[2..9], "\n";
                    last;
                };
            };
        };
    };
    for my $item1 (@pos_n_u) {
        for my $item2 (@array) {
            my ($s1, $e1) = @$item1;
            my ($s2, $e2) = (@$item2[-4], @$item2[-3]);
            if  (@$item2[1] eq "-") {
                if ($s1 == $s2 && $e1 == $e2) {
                    print $resultnr join "\t", $id, @$item2[0], @$item2[2..5], @$item2[7], @$item2[6], @$item2[8..9], "\n";
                    last;
                };
            };
        };
    }; 
};
close $resultnr;

sub uniq {
    my %seen;
    grep !$seen{$_->[0]}{$_->[1]}++, @_;
}
