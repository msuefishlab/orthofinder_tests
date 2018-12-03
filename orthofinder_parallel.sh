#!/bin/bash

# use conda installs for orthofinder, blast, parafly
# use Git pull for HpcGridRunner (in ~/GitRepos/)
# use module MAKER/2.31.9 

# run from inside fasta directory

# format the fastas/blastdbs, gather necessary commands
# using my conda orthofinder environment
source /mnt/home/lueckeda/anaconda3/bin/activate my_orthofinder_env
orthofinder -f $PWD -op > orthofinder_op.out
source /mnt/home/lueckeda/anaconda3/bin/deactivate

# formatted files are in Results/WorkingDirectory
# this will automatically go into newest Results directory (the one that was just created)
latest=`ls Results* -td | head -n1`
cd $latest/WorkingDirectory
ls

# split the formatted fastas for each species 
for i in $(ls Species*.fa); do
	fasta_tool --split $i --chunks 25
done

# probably want to make a subdirectory to hold the split fastas
mkdir fasta_subsets
mv Species*_*.fasta fasta_subsets

# end goal are pairwise blast output files BlastX_Y.txt where X is query and Y is db
# want to submit all the blasts at once
# probably want to write a commands file for hpc_gridrunner (rather than use it's built-in fasta split blast tool), or will have to wait for each fasta separately

# loop to write all blastp commands called from inside fasta_subsets directory:
# outer loop goes through the prepared blast database files, formatted with names BlastDBSpeciesX.ext
# inner loop inside a conditional, only runs when outer loop encounters a new species' blastdb, rather than same species with new .ext (by comparing x and k variables)
# out files are formatted as BlastX_Y-i.txt, where i is the fasta subset identifier, will make it easy to cat and write to the desired BlastX_Y.txt files
cd fasta_subsets 
x='x'
for j in $(ls ../BlastDBSpecies*); do 
	k=`echo $j | cut -d '/' -f2 | cut -d'.' -f1`
	absk=`abspath $j | cut -d'.' -f1`
	l=`echo $k | sed -e "s/^.*\([0-9]\+\)$/\1/"`
	if [ $k != $x ]; then 
		for i in $(ls *.fasta); do 
			q=`echo $i | cut -d'.' -f1 | cut -d'_' -f1 | sed -e "s/^.*\([0-9]\+\)$/\1/"`
			p=`echo $i | cut -d'.' -f1 | cut -d'_' -f2`
			echo "blastp -outfmt 6 -evalue 0.001 -query $PWD/$i -db $absk -out $PWD/Blast"$q"_"$l"-"$p".txt"
		done
	fi
	x=$k
done > orthofinder_blastp.commands

# use HpcGridRunner to run the commands file - each is submitted to its own node
~/GitRepos/HpcGridRunner/hpc_cmds_GridRunner.pl -c orthofinder_blastp.commands --grid_conf ~/GitRepos/orthofinder_tests/HGR_BLAST.config --parafly

# cat the blast results into appropriately named files in WorkingDirectory
cd ..
for i in $(ls fasta_subsets/Blast*.txt); do 
	echo $i 
	n=`echo $i | cut -d'-' -f1 | cut -d'/' -f2`
	touch $n.txt
done




