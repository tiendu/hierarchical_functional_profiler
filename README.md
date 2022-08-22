# funcprofiler
This tool will take in the output from DIAMOND blastx and search for the hierarchical classification of functions from KEGG.

## How to use

1) Get the Brite hierarchy using KEGG API from https://rest.kegg.jp/get/br:ko00001/json

2) Get the UniProt-Sprot database from https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz unzip it then extract the UniProt ID by running this command 
```
awk '/>/ {match($0, /\|(.+)\|/, a); print a[1]}' uniprot_sprot.fasta
```
