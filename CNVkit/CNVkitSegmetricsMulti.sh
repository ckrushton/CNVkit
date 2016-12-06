#! /bin/bash

echo ""

if [[ $# -eq 0 ]]; then

	echo "Usage: RunSegmetricsMulti.sh [file1.cn{r,s} [file2.cn{r,s}... ]]"
	echo ""
	echo "Runs cnvkit.py segmetrics on .cnr and .cns samples."
	echo "Specifies --ci and --sem, for use with advanced versions of cnvkit.py call."
	echo ""
	echo "Have a nice day"
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
	else

		echo "WARNING: $file is not a .cnr or .cns file. Ignoring..."
	fi

done


# Runs cnvkit.py segmetrics
source activate python2
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

		echo "ERROR: No .cns file could be found for $cnrFile. Skipping..."
		continue
	fi

	segArgs="$cnrFile -s $cnsFile --ci --sem"
	cnvkit.py segmetrics $segArgs

done

source deactivate