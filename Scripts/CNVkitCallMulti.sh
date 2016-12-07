#!/bin/bash

# REQUIRES PYTHON 2.7 FOR GRCh38-based DATA

# THIS SCRIPT IS OLD
# I AM AWARE THE SYNTAX AND FORMATTING IS BAD
# But it works

echo ""
if [[ $# -eq 0 ]]
then
	echo "Usage: CNVkitCallMulti.sh [options] [file1 [file2... ]]"
	echo "Runs cnvkit.py call on multiple .cns files with different purity values"
	echo "Ensure coresponding files share the same base name"
	echo ""
	echo "Requires Python 2.7 EXACTLY (Not newer)"
	echo "Python 3.x does not work with GRCh38-based data"
	echo ""
	echo "Required Positional Arguments"
	echo "	<.cns file> 	A segments file, output of cnvkit.py segment"
	echo "	<.vcf file> 	An optional .vcf file, used to calculate BAF for each sample"
	echo ""
	echo "Optional Positional Arguments"
	echo "	<.cnr file> 	A regions file, output of cnvkit.py fixed. Used in --scatter"
	echo ""
	echo "The following options are availible"
	echo "	-p <.txt> 	A file containing the tumor purity values for each sample"
	echo "	-o <dir> 	Output path for .call.cns files"
	echo "	--scatter 	Runs cnvkit.py scatter on each .call.cns file"
	echo "	--diagram 	Runs cnvkit.py diagram on each .call.cns file"
	echo "	-f <mode> 	Filtering method {ampdel,cn,ci,sem}"
	echo "	-c <mode> 	Centering method {mean, median, mode, biweight}"
	echo ""
	exit
fi

samplePurityFile="None"
inputCNS=()
inputCNR=()
inputVCF=()
scatter=false
diagram=false
filterType="None"
centerType="None"

cmdArgs=($@)

# Processes command line arguments
currentArg=-1
argAlreadyTreated=false
for arg in ${cmdArgs[*]}
do

	((currentArg++))
	if [ $argAlreadyTreated == true ]
	then
		argAlreadyTreated=false
		continue
	fi

	# If an option is specified
	if [ ${arg:0:1} == "-" ]
	then

		# If an option is specified that requires an additional parameter
		if [ $arg == "-p" ] || [ $arg == "-o" ] || [ $arg == "-f" ] || [ $arg == "-c" ]
		then

			# Checks to make sure there is a another argument
			if [ $((currentArg+1)) -lt ${#cmdArgs[*]} ]
			then

				# If the option specifies a path, skip the file exists check
				if [ $arg == "-o" ]
				then

					outputPath=${cmdArgs[$((currentArg+1))]}

				# If the purity file is specified, set the variable
				elif [ $arg == "-p" ]
				then 

					# Checks to make sure the file exists
					if [ ! -e ${cmdArgs[$((currentArg+1))]} ]
					then

						echo "The file $arg could not be found. Skipping"
					else					
						samplePurityFile=${cmdArgs[$((currentArg+1))]}	
					fi


				elif [ $arg == "-f" ]
				then
					filterType=${cmdArgs[$((currentArg+1))]}

				elif [ $arg == "-c" ]
				then
					centerType=${cmdArgs[$((currentArg+1))]}

				fi

				argAlreadyTreated=true
			# If there is no next argument for these parameters, return an error
			else

				echo "ERROR: No parameter was specified for $arg"
				exit
			fi

		# Sets the output options
		elif [ $arg == "--scatter" ]
		then

			scatter=true

		elif [ $arg == "--diagram" ]
		then

			diagram=true

		# If an unsuported option was specified, print out an error message
		else

			echo "ERROR: The option $arg is not supported"
			exit
		fi

	# If there is no "-" at the start, the input is sorted into the apropriate array
	else
		
		# Checks to make sure the file exists
		if [ ! -e $arg ]
		then

			echo "The file $arg could not be found. Skipping"

		else

			fileExtension=${arg##*.}

			# Adds a .bam file to the list
			if [ $fileExtension == "cns" ]
			then
				inputCNS+=($arg)

			elif [ $fileExtension == "cnr" ]
			then
				inputCNR+=($arg)
			elif [ $fileExtension == "vcf" ]
			then 
				inputVCF+=($arg)

			else
				echo "$arg is an unknown file type, ignoring..."
			fi
		fi
	fi
done


if [ $samplePurityFile == "None" ]
then 
	echo "WARNING: No purity file was provided"
	echo "Assuming all samples are 100% pure"

# Checks arguments to ensure that the required files were provided
elif [ ${#inputCNS[*]} -eq 0 ]
then
	echo "ERROR: No .cns files were provided"
	exit
elif [ $filterType != "ampdel" ] && [ $filterType != "cn" ] && [ $filterType != "ci" ] && [ $filterType != "sem" ] && [ $filterType != "None" ]
then
	echo "ERROR: The filter $filterType is not valid."
	echo "	Try ampdel,cn,ci, or sem"
	exit
elif [ $centerType != "mean" ] && [ $centerType != "median" ] && [ $centerType != "mode" ] && [ $centerType != "biweight" ] && [ $filterType != "None" ]
	then
	echo "ERROR: The centering method $centerType is not supported."
	echo " 	Try mean, median, mode, or biweight."
	exit

fi

# Prints out a log file of the commands run
startTime=$(date)
outputLogFile="${outputPath}LogFile.txt"
cnvkitVersion=$(cnvkit.py version)
touch $outputLogFile

echo "CNVkitCallMulti.sh: Script started at $startTime" > $outputLogFile
echo "" >> $outputLogFile
echo "===========================================================" >> $outputLogFile
echo "" >> $outputLogFile
echo "The following parameters were used:" >> $outputLogFile
echo "		Output Path: $outputPath" >> $outputLogFile
echo "		Purity File: $samplePurityFile" >> $outputLogFile
echo "		Filtering Method: $filterType" >> $outputLogFile
echo "		Centering Type: $centerType" >> $outputLogFile
echo "		Scatter: $scatter" >> $outputLogFile
echo "		Diagram: $diagram" >> $outputLogFile
echo "" >> $outputLogFile
echo "The following files were used:" >> $outputLogFile
echo "CNS files:" >> $outputLogFile
for cnsFile in ${inputCNS[*]}
do
	echo "$cnsFile" >> $outputLogFile
done
echo "" >> $outputLogFile
echo "CNR files:" >> $outputLogFile
for cnrFile in ${inputCNR[*]}
do
	echo "$cnrFile" >> $outputLogFile
done
echo "" >> $outputLogFile
echo "vcf Files:" >> $outputLogFile
for vcfFile in ${inputVCF[*]}
do
	echo "$cnsFile" >> $outputLogFile
done
echo "" >> $outputLogFile
echo "" >> $outputLogFile
echo "CNVkit Version: $cnvkitVersion" >> $outputLogFile
echo "" >> $outputLogFile
echo "CNVkit Call Standard Error Stream:" >> $outputLogFile
echo "===============================================================" >> $outputLogFile


# THIS IS REQUIRED FOR CRCh38-based DATA
# Ensure python2 is installed
source activate python2

for cnsFile in ${inputCNS[*]}
do

	cnvkitCallCom=""
	
	# Obtains the base name of the input
	cnsNoExtensions=${cnsFile%%.*}
	baseCnsName=${cnsNoExtensions##*/}
	matchedVCF="None"

	# If a filter was specified, use it
	if [ $filterType != "None" ]
	then
		cnvkitCallCom+="--filter $filterType "
	fi

	# If a centering method was specified, use it
	if [ $centerType != "None" ]
		then
		cnvkitCallCom+="--center $centerType"
	fi

	#Pairs each .cns with a .vcf, if one was provided
	if [ ${#inputVCF[*]} -gt 0 ]
	then

		for vcfFile in ${inputVCF[*]}
		do

			# Normalize the .vcf names
			noPathVCF=${vcfFile##*/}
			baseVCFName=${noPathVCF%%.*}

			# If there is a dash in the filename, it is replaced with an underscore
			if [[ $vcfFile == *-* ]]
			then
				vcfNameCorrected=${baseVCFName/-/_}
			else 
				vcfNameCorrected=${baseVCFName}
			fi

			# Normalizes length
			while [ ${#vcfNameCorrected} -lt 8 ]
			do
				vcfNameCorrected=${vcfNameCorrected/_/_0}
				echo $vcfNameCorrected

			done

			if [[ $vcfNameCorrected == $baseCnsName ]]
			then

				matchedVCF=$vcfFile
				break
			fi

		done

		# If a .vcf file was found, add it to the commands. Otherwise, print out a warning
		if [ $matchedVCF != "None" ]
		then
			cnvkitCallCom+=" -v $matchedVCF"
		else
			echo "ERROR: No .vcf file was found for $cnsFile. Proceeding..."

		fi

	fi

	samplePurity=-1
	cnsNoUnderscore=${baseCnsName%_*}${baseCnsName#*_}

	# If a purity estimate was provided, find the purity estimate for this sample
	if [ $samplePurityFile != "None" ]
	then
		while read purityLine;
		do
			purityTokens=($purityLine)
			purityTokenName=${purityTokens[0]}
			if [ $purityTokenName == $cnsNoUnderscore ]
			then
				samplePurity=${purityTokens[1]}
				break
			fi
			
		done<$samplePurityFile


	fi
	# If sample purity was not found in the file, assume a purity of 100%
	if [ $samplePurity != -1 ]
	then
		cnvkitCallCom+=" -m clonal --purity $samplePurity"
	fi

	# Finalizes call commands
	cnsOutputFile=${outputPath}${baseCnsName}.call.cns
	cnvkitCallCom+=" -o $cnsOutputFile"

	cnvkit.py call $cnsFile $cnvkitCallCom &>> $outputLogFile

	# If --scatter or --diagram is specified, the coresponding .cnr is located
	matchedCnr="None"
	# Finds the coresponding .cnr file
	if [ $scatter == true ] || [ $diagram == true ]
	then

		# Creates the commands for --scatter and --diagram
		scatterCom="-s $cnsOutputFile -o ${outputPath}${baseCnsName}.call.scatter.pdf"
		if [ $matchedVCF != "None" ]
			then
			scatterCom+=" -v $matchedVCF"
		fi


		diagramCom="-s $cnsOutputFile -o ${outputPath}${baseCnsName}.call.diagram.pdf"

		for cnrFile in ${inputCNR[*]}
		do
			# Normalize the .vcf names
			cnrNoExtensions=${cnrFile%%.*}
			baseCnrName=${cnrNoExtensions##*/}

			if [[ $baseCnrName == $baseCnsName ]]
			then

				matchedCnr=$cnrFile
				break
					
			fi

		done

		if [ $matchedCnr == "None" ]
		then
			echo "WARNING: No .cnr file was found for $cnsFile"
			echo "--scatter or --diagram may be incomplete"

		else
			scatterCom="$matchedCnr $scatterCom"
			diagramCom="$matchedCnr $diagramCom"
		fi

		# Runs visualization commands on corrected .cns
		if [ $scatter == true ] 
		then 

			cnvkit.py scatter $scatterCom &>> $outputLogFile

		fi

		if [ $diagram == true ]
		then

			cnvkit.py diagram $diagramCom &>> $outputLogFile
		fi
	fi

done

source deactivate