#! /bin/bash
# Runs cnvkit.py segmetrics on multiple .cns files, using the specified parameters

# Parameters
# =======================================================================================
outputDir="./"
ci=true
sem=true
bootstrap=200
alpha=0.05
# =======================================================================================



echo ""

if [[ $# -eq 0 ]]; then

	echo "Usage: RunSegmetricsMulti.sh [file1.cn{r,s} [file2.cn{r,s}... ]]"
	echo ""
	echo "Runs cnvkit.py segmetrics on .cnr and .cns samples."
	echo ""
	echo "The following parameters are specified:"
	echo "	Output Directory: $outputDir"
	echo "	Confidence Interval: $ci"
	echo "	Standard Error of the Mean: $sem"
	echo "	Bootstrap Number: $bootstrap"
	echo "	Alpha confidence threshhold: $alpha"
	echo ""
	exit

fi

cnrFiles=()
cnsFiles=()
inputFiles=($@)

for file in ${inputFiles[*]}; do

	fileExt=${file##*.}

	if [[ $fileExt == "cns" ]]; then

		cnsFiles=(${cnsFiles[*]} $file)
	elif [[ $fileExt == "cnr" ]]; then

		cnrFiles=(${cnrFiles[*]} $file)
	fi

done

# Creates an output log
startTime=$(date)
cnvkitVersion=$(cnvkit.py version)
outputLogFile="${outputDir}LogFile.txt"
touch $outputLogFile

echo "CNVkitSegmetricsMulti.sh: Started on $startTime" > $outputLogFile
echo "" >> $outputLogFile
echo "=================================================================" >> $outputLogFile
echo "" >> $outputLogFile
echo "The following parameters were used:" >> $outputLogFile
echo "	Output Directory: $outputDir" >> $outputLogFile
echo "	Confidence Interval: $ci" >> $outputLogFile
echo "	Standard Error of the Mean: $sem" >> $outputLogFile
echo "	Bootstrap Number: $bootstrap" >> $outputLogFile
echo "	Alpha confidence threshhold: $alpha" >> $outputLogFile
echo "" >> $outputLogFile
echo "The following files were used" >> $outputLogFile
echo "cns files:" >> $outputLogFile
for cnsFile in ${cnsFiles[*]}; do
	echo "$cnsFile" >> $outputLogFile
done
echo "" >> $outputLogFile
echo "cnr files:" >> $outputLogFile
for cnrFile in ${cnrFiles[*]}; do
	echo "$cnrFile" >> $outputLogFile
done
echo "" >> $outputLogFile
echo "" >> $outputLogFile
echo "CNVkit version: $cnvkitVersion" >> $outputLogFile
echo "" >> $outputLogFile
echo "CNVkit Segmetrics standard error stream:" >> $outputLogFile
echo "==================================================================" >> $outputLogFile

# Runs cnvkit.py segmetrics
for cnrFile in ${cnrFiles[*]}; do

	# Obtains the base name of the .cnr file
	cnrNoPath=${cnrFile##*/}
	cnrBaseName=${cnrNoPath%%.*}

	# Searches for a matching .cns file
	matchingCns="None"
	for cnsFile in ${cnsFiles[*]}; do

		cnsNoPath=${cnsFile##*/}
		cnsBaseName=${cnsNoPath%%.*}

		if [[ $cnrBaseName == $cnsBaseName ]]; then
 
			matchingCns=$cnsFile
			break
		fi

	done

	if [[ $matchingCns == "None" ]]; then

		echo "" >> $outputLogFile
		echo "WARNING: No .cns file could be found for $cnrFile. Skipping..." >> $outputLogFile
		echo "" >> $outputLogFile
		continue
	fi

	segArgs="$cnrFile -s $cnsFile"

	if [[ $ci == "true" ]] && [[ $sem == "true" ]]; then

		# If specified, adds ci
		if [[ $ci == "true" ]]; then

			segArgs="$segArgs --ci"

		fi

		# If specified, adds sem
		if [[ $sem == "true" ]]; then

			segArgs="$segArgs --sem"
		fi

		segArgs="$segArgs -b $bootstrap -a $alpha"

	fi

	segArgs="$segArgs -o ${outputDir}${cnrBaseName}.segmetrics.cns"

	cnvkit.py segmetrics $segArgs &>> $outputLogFile

done

# Finalizes the output log
echo "" >> $outputLogFile
echo "========================================================================" >> $outputLogFile
echo "" >> $outputLogFile
echo "Segmetrics Complete" >> $outputLogFile
echo "Results in $outputDir" >> $outputLogFile
echo "CNVkitSegmetricsMulti.sh: Finished on $(date)" >> $outputLogFile