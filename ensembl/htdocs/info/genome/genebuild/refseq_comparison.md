# How gene annotation in Ensembl and RefSeq differs

Some species have a 'RefSeq comparison' attribute that you can find on the Gene Summary pages. There are four types of comments:

1. No overlapping RefSeq annotation found
2. Overlapping RefSeq annotation not matched
3. Overlapping RefSeq Gene ID [93759](http://www.ensembl.org/Mus_musculus/Gene/Summary?g=ENSMUSG00000020063;r=10:63319005-63381704) matches and has similar biotype of protein_coding
4. Overlapping RefSeq Gene ID [667103](http://www.ensembl.org/Mus_musculus/Gene/Summary?g=ENSMUSG00000087181;r=2:60098406-60098714;t=ENSMUST00000140763) matches but different biotype of protein_coding
These comments are a guideline only and we encourage you to compare the annotation that you find in Ensembl with annotation from RefSeq yourself. 

## How are the matches decided?
The rule for whether or not the Ensembl an RefSeq genes match are basic. The logic is as follows:

* For each gene in Ensembl, fetch all imported overlapping genes from RefSeq
* If no RefSeq genes are fetched, the Ensembl gene is tagged with the comment, "No overlapping RefSeq annotation found".
* Overlapping RefSeq genes may be on the opposite strand. In this case, they are not considered for matching and the Ensembl gene may be tagged with the comment, "Overlapping RefSeq annotation not matched".
* If a RefSeq gene overlaps the Ensembl gene on the same strand, we will not automatically consider them as a match. They will only be considered a match in two cases, either:
  * both genes have been assigned the same name, or
  * the length, start and end of the RefSeq gene is within 10% of the length of the Ensembl gene's length, start and end. 
* If a match is found, we report whether the biotypes are similar or not.


# Which species will have these comments?

These comments are only available where we have annotation imported from RefSeq. This is limited both by the species that are annotated by RefSeq and by our frequency in importing their annotation. [This link](ftp://ftp.ncbi.nlm.nih.gov/genomes/) will show you a list of species where RefSeq annotation is available.

Please note that these comments will be updated only when we import new annotation from RefSeq and may therefore be out of sync with the latest RefSeq annotation.
