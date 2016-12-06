#!/bin/bash

# From input files, identifies .bam files, and sorts .bam files into tumor and normals based upon the presence of a 'N' in the file name of normals
# ONLY NORMALS MUST CONTAIN A CAPITAL 'N' FOR THIS SCRIPT TO WORK CORRECTLY

echo ""

#########################################################################################################################
# Options for cnvkit.py batch
referenceGenome="/morinlab/reference/igenomes/Homo_sapiens/GSC/GRCh38/Sequence/WholeGenomeFasta/GRCh38_no_alt.fa"
targetBed="/home/crushton/Ex_Realn_CNV/CNVkit/HelperFiles/agilent_sureselect_all_exons_v5_and_utr.annotated_PCG_only.No_Dupl.bed"
accessFile="/home/crushton/Ex_Realn_CNV/CNVkit/HelperFiles/GRCh38_access.bed"
threadNum="10"
outputDir="/home/crushton/Ex_Realn_CNV/CNVkit/Batch/"
#########################################################################################################################


if [[ $# -eq 0 ]]; then

	echo "Usage: CNVkitBatchWrapper.sh [file1 [file2... ]]"
	echo ""
	echo "Identifies tumor and normal bam files by the presence"
	echo "of an 'N' in the file name of normals."
	echo "Ignores non-bam files."
	echo "Please ensure your files are named apropriately."
	echo ""
	echo "cnvkit batch is run on these files, using the following options:"
	echo "	--drop-low-coverage"
	echo "	-p $threadNum "
	echo "	-f $referenceGenome"
	echo "	-t $targetBed"
	echo "	-g $accessFile"
	echo "	-d $outputDir"
	exit

fi

inputFiles=($@)
normalFiles=()
tumorFiles=()

for file in ${inputFiles[*]}; do

	# Ignores non-bam files
	fileExtension=${file##*.}

	if [[ $fileExtension != "bam" ]]; then
		continue
	fi

	if [[ $file == *'N'* ]]; then
		normalFiles=(${normalFiles[*]} $file)
	else
		tumorFiles=(${tumorFiles[*]} $file)
	fi

done

# Logs the commands run
logFile="${outputDir}LogFile.txt"
touch $logFile
cnvkitVer=$(cnvkit.py version)
echo "CNVkitBatchWrapper.sh: Run on $(date)" > $logFile
echo "" >> $logFile
echo "The following options were used:" >> $logFile
echo "##########################################################" >> $logFile
echo "Tumor BAMs run: " >> $logFile

for tFile in ${tumorFiles[*]}; do
	echo "$tFile" >> $logFile
done

echo "" >> $logFile
echo "Normal BAMs used to construct reference: " >> $logFile

for nFile in ${normalFiles[*]}; do
	echo "$nFile" >> $logFile
done

echo "" >> $logFile
echo "--drop-low-coverage" >> $logFile
echo "-p $threadNum " >> $logFile
echo "-f $referenceGenome" >> $logFile
echo "-t $targetBed" >> $logFile
echo "-g $accessFile" >> $logFile
echo "-d $outputDir" >> $logFile
echo "" >> $logFile
echo "All other batch options were left at default" >> $logFile
echo "" >> $logFile
echo "Run on cnvkit version $cnvkitVer" >> $logFile
echo "" >> $logFile
echo "CNVkit output:" >> $logFile
echo "##########################################################" >> $logFile


batchCommands="${tumorFiles[*]} --drop-low-coverage -p $threadNum -f $referenceGenome -t $targetBed -g $accessFile -d $outputDir -n ${normalFiles[*]}"
cnvkit.py batch $batchCommands &>> $logFile
