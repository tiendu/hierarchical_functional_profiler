use strict;
use warnings;
use Data::Dumper;

my $file_path = shift @ARGV;
my $file = $file_path =~ s/.*\///r;
my ($file_name, $file_extension) = $file =~ /^(.+)\.([^.]+)$/;

open my $input, "<:utf8", $file_path or die qq{Can't open $file_path: $!\n};
my %infos_hash;
while (<$input>) {
    chomp;
    my @fields = split "\t";
#     filtering follows this guide: 10.1002/0471250953.bi0301s42
    if ($fields[2] > 30 && $fields[-2] < 1.0e-5 && $fields[-1] > 50) {
        $infos_hash{$fields[0]} = [] unless exists $infos_hash{$fields[0]};
        push @{$infos_hash{$fields[0]}}, [@fields[1 .. $#fields]];
    };
    last if eof $input;
};
close $input;

open my $temp, ">:utf8", "temp";
for my $id (sort keys %infos_hash) {
    my @array = @{$infos_hash{$id}};
    my @positions_positive;
    my @positions_negative;
    for my $item (@array) {
        if (@$item[5] < @$item[6]) {
            push @positions_positive, [@$item[5], @$item[6]];
        } else {
            push @positions_negative, [@$item[6], @$item[5]];
        };
    };
    my @uniq_positive_positions = uniq(@positions_positive);
    my @removal_positive;    
    for my $item_1 (@uniq_positive_positions) {
        for my $item_2 (@uniq_positive_positions) {
            unless ($item_1 == $item_2) {
                my ($start_1, $end_1) = @$item_1;
                my ($start_2, $end_2) = @$item_2;
                if ($start_1 >= $start_2 && $end_1 <= $end_2) {
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
                if ($start_1 >= $start_2 && $end_1 <= $end_2) {
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
            my ($start_2, $end_2) = (@$item_2[5], @$item_2[6]);
            if (@$item_2[5] < @$item_2[6]) {
                if ($start_1 == $start_2 && $end_1 == $end_2) {
                    my $name = $id . "_" . $start_1 . "_" . $end_1;
                    print $temp join("\t", $name, @$item_2, "\n");
                    last;
                };
            };
        };
    };
    for my $item_1 (@uniq_positions_negative) {
        for my $item_2 (@array) {
            my ($start_1, $end_1) = @$item_1;
            my ($start_2, $end_2) = (@$item_2[5], @$item_2[6]);
            if (@$item_2[5] > @$item_2[6]) {
                if ($start_1 == $start_2 && $end_1 == $end_2) {
                    my $name = $id . "_" . $start_1 . "_" . $end_1;
                    print $temp join("\t", $name, @$item_2, "\n");
                    last;
                };
            };
        };
    }; 
};
close $temp;

open my $temp2, "<:utf8", "temp";
my %infos_hash2;
while (<$temp2>) {
    chomp;
    my @fields = split "\t";
#     filtering follows this guide: 10.1002/0471250953.bi0301s42
    if ($fields[2] > 30 && $fields[-2] < 1.0e-5 && $fields[-1] > 50) {
        $infos_hash2{$fields[0]} = [] unless exists $infos_hash2{$fields[0]};
        push @{$infos_hash2{$fields[0]}}, [@fields[1 .. $#fields]];
    };
    last if eof $temp2;
};
close $temp2;

open my $output, ">:utf8", "filtered_${file_name}.${file_extension}";
for my $id (sort keys %infos_hash2) {
    my @array = @{$infos_hash2{$id}};
    my %find;
    for my $item (@array) {
        $find{max_ident} = @{$item}[1] unless $find{max_ident};
        $find{max_len} = abs(@{$item}[5] - @{$item}[6]);
        $find{key} = $id unless $find{key};
        $find{vals} = $item unless $find{vals}; 
        if ($find{max_ident} < @{$item}[1] && $find{max_len} < abs(@{$item}[5] - @{$item}[6])) {
            $find{max_ident} = @{$item}[1];
            $find{max_len} = abs(@{$item}[5] - @{$item}[6]);
            $find{key} = $id;
            $find{vals} = $item;
        };
    };
    my @name = split("_", $find{key});
    my $fixed_name = join("_", @name[0 .. $#name - 2]);
    print $output join("\t", $fixed_name, @{$find{vals}}, "\n");
};
close $output;

unlink "temp";

sub uniq {
    my %seen;
    grep !$seen{$_->[0]}{$_->[1]}++, @_;
    grep !$seen{"$_->[0],$_->[1]"}++, @_;
}
