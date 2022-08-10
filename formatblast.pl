use strict;

my $result_path = shift @ARGV;
my $result_path_cp = $result_path;
$result_path_cp =~ s/.*\///;
my $file_name = $1 if $result_path_cp =~ /^(.+)\.([^.]+)$/;

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
    if ($ident > 30 && $evalue < 1.0e-5 && $bit > 50) {
        $infos_hash{$id} = [] unless exists $infos_hash{$id};
        push @{$infos_hash{$id}}, @info;
    };
    last if eof $result;
};
close $result;

open my $nr_result, ">:utf8", "filt_${file_name}.tsv";
my %id_positions_hash;
for my $id (sort keys %infos_hash) {
    my @array = @{$infos_hash{$id}};
    my @positions_positive;
    my @positions_negative;
    for my $item (@array) {
        if (@$item[1] eq "+") {
            push @positions_positive, [@$item[-4], @$item[-3]];
        } elsif (@$item[1] eq "-") {
            push @positions_negative, [@$item[-4], @$item[-3]];
        };
    };
    
    my @uniq_positive_positions = uniq(@positions_positive);
    my @removal_positive;    
    for my $item_1 (@uniq_positive_positions) {
        for my $item_2 (@uniq_positive_positions) {
            unless ($item_1 == $item_2) {
                my ($start_1, $end_1) = @$item_1;
                my ($start_2, $end_2) = @$item_2;
                if ($start_1 == $start_2 && $end_1 < $end_2) {
                    push @removal_positive, $item_1;
                };
            };
        };
    };
    my @uniq_removal_positive = uniq(@removal_positive);
    for (@uniq_removal_positive) {
        my $index = 0;
        $index++ until $uniq_positive_positions[$index] == $_;
        splice(@uniq_positive_positions, $index, 1);
    };
    
    my @uniq_positions_negative = uniq(@positions_negative);
    my @removal_negative;
    for my $item_1 (@uniq_positions_negative) {
        for my $item_2 (@uniq_positions_negative) {
            unless ($item_1 == $item_2) {
                my ($start_1, $end_1) = @$item_1;
                my ($start_2, $end_2) = @$item_2;
                if ($start_1 == $start_2 && $end_1 < $end_2) {
                    push @removal_negative, $item_1;
                };
            };
        };
    };
    my @uniq_removal_negative = uniq(@removal_negative);
    for (@uniq_removal_negative) {
        my $index = 0;
        $index++ until $uniq_positions_negative[$index] == $_;
        splice(@uniq_positions_negative, $index, 1);
    };
    for my $item_1 (@uniq_positive_positions) {
        for my $item_2 (@array) {
            my ($start_1, $end_1) = @$item_1;
            my ($start_2, $end_2) = (@$item_2[-4], @$item_2[-3]);
            if  (@$item_2[1] eq "+") {
                if ($start_1 == $start_2 && $end_1 == $end_2) {
                    print $nr_result join "\t", $id, @$item_2[0], @$item_2[2..9], "\n";
                    last;
                };
            };
        };
    };
    
    for my $item_1 (@uniq_positions_negative) {
        for my $item_2 (@array) {
            my ($start_1, $end_1) = @$item_1;
            my ($start_2, $end_2) = (@$item_2[-4], @$item_2[-3]);
            if  (@$item_2[1] eq "-") {
                if ($start_1 == $start_2 && $end_1 == $end_2) {
                    print $nr_result join "\t", $id, @$item_2[0], @$item_2[2..5], @$item_2[7], @$item_2[6], @$item_2[8..9], "\n";
                    last;
                };
            };
        };
    }; 
};
close $nr_result;

sub uniq {
    my %seen;
    grep !$seen{$_->[0]}{$_->[1]}++, @_;
#     grep !$seen{"$_->[0],$_->[1]"}++, @_;
}
