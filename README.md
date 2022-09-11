# functional profiler using KEGG hierarchies
This tool will take in the output from DIAMOND blastx and search for the hierarchical classification of functions from KEGG.

## How to use

First, we need to get the KEGG Orthology corresponding to the UniProt ID.

1) Get the UniProt-Sprot database from https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz unzip it then extract the UniProt ID by running this command 
```
awk '/>/ {match($0, /\|(.+)\|/, a); print a[1]}' uniprot_sprot.fasta >> uniprot_id.txt
```

2) With the UniProt ID in hands, now we can convert it to KEGG Genes
```
for line in $(cat uniprot_id.txt); do curl -L https://rest.kegg.jp/conv/genes/${line} >> uniprot_genes.tsv; done
```

3) And get the KO ID from KEGG Genes.
```
for line in $(awk -v FS="\t" '{print $2}'); do curl -L https://rest.kegg.jp/link/ko/${line} >> genes_ko.tsv; done
```

4) Then we get the Brite hierarchy from https://rest.kegg.jp/get/br:ko00001/json

This will give us three files for the uniprot2ko.pl. Run the uniprot2ko.pl with this command.
```
perl uniprot2ko.pl json uniprot_genes.tsv genes_ko.tsv
```

==> This will generate a file with UniProt ID and the corresponding Brite hierarchy.

We also need to filter the result from DIAMOND blastx. Redundant results e.g., short ORFs, are expected from DIAMOND blastx. Use the formatblast.pl to do it.
```
perl formatblast.pl result_from_DIAMOND_blastx
```

Finally, use the findfunction.pl to look for the Brite hierarchy.
```
perl findfunction.pl uniprot_brite.tsv filtered_result_from_DIAMOND_blastx
```
