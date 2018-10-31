#!/bin/bash

#  run_orthofinder_test.sh
#  wrapper script to decompress files, move into working directory, and run orthoscript slurm scripts
#  assumes files placed as from data_download.sh
#  Created by David Luecke on 10/31/18.
#  

if [ ! -d $SCRATCH/orthofinder ]; then
    mkdir $SCRATCH/orthofinder
fi

read -p "Perform Orthofinder on pep.all files? y/n: " PEPALL
read -p "Perform Orthofinder on pep.abinitio files? y/n: " PEPABINITIO

### anaylsis for pep.all files ###
if [ $PEPALL == 'y' ]; then
while true; do  # use the while loop so we can break out of this code block at checkpoint

if [ ! -d $SCRATCH/orthofinder/peptide_all ]; then
    mkdir $SCRATCH/orthofinder/peptide_all
fi
cd $SCRATCH/orthofinder/peptide_all

# make sure the files are what we want to analyze, if not move to the abinitio block
echo "Going to run Orthofinder on following files:"
ls $SCRATCH/data_downloads/*/*.pep.all.fa.gz # this directory structure follows data_download, and file string is same in all Ensembl peptide files
read -p "Do you want to proceed? y/n: " CHECK1
[ $CHECK1 == 'y' ] || break


for i in $(ls $SCRATCH/data_downloads/*/*.pep.all.fa.gz)
do
    j=`echo $i | rev | cut -d'/' -f1 | rev | cut -d'.' -f1`  # using the Ensemble file name's first field before a '.' as new names for unzipped files
    zcat $i > $j.fa  # already in new directory
done

# this .sb script runs Orthofiner with all fastas in $SCRATCH/orthofinder/peptide_all
sbatch TestOrthofinder_All.sb
break # don't actually want to loop
done
fi
### end analysis for pep.all ###


### analysis for pep.abinitio files, mirror of above ###
if [ $PEPABINITIO == 'y' ]; then
while true; do

if [ ! -d $SCRATCH/orthofinder/peptide_abinitio ]; then
    mkdir $SCRATCH/orthofinder/peptide_abinitio
fi
cd $SCRATCH/orthofinder/peptide_abinitio

# make sure the files are what we want to analyze, if not move to end of script
echo "Going to run Orthofinder on following files:"
ls $SCRATCH/data_downloads/*/*.pep.abinitio.fa.gz # this directory structure follows data_download, and file string is same in all Ensembl peptide files
read -p "Do you want to proceed? y/n: " CHECK2
[ $CHECK2 == 'y' ] || break

# using the Ensemble file name first field before a '.' as new names for unzipped files
for k in $(ls $SCRATCH/data_downloads/*/*.pep.abinitio.fa.gz)
do
    l=`echo $k | rev | cut -d'/' -f1 | rev | cut -d'.' -f1`
    zcat $k > $l.fa
done

# this .sb script runs Orthofinder with all fastas in $SCRATCH/orthofinder/peptide_abinitio
sbatch TestOrthofinder_AbInitio.sb
break
done
fi
### end analysis for pep.abinitio ###

echo "All done, check SLURM outfiles for more information"
