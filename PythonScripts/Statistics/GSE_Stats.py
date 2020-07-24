# GEO Metadata Parser (GSE: Series)
# 1. Generate Statistical Counts from Cached-Dictionary Files

# Python imports
import os
from collections import defaultdict
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from XZPickle import XZRead

# Python Version Check
# Requirement: CPython 3.7.X
assert PyCheckLenient('CPython', '3', '7')

# Declaring Global Variables
inputDir = '{0}/GeoData/GSE/'.format(os.getenv('DL_CACHE_DIR'))
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# ------------------------------ MAIN ------------------------------
# Preparations
fileList = os.listdir(inputDir)
resultDict = dict({
	'array_and_seq': 0,
	'array_and_seq_and_tri_taxa': 0
})

# Parse Dictionary Files
print('Parsing Files')
for currentFile in fileList:
	inputDict = XZRead('{0}{1}'.format(inputDir, currentFile))
	tempDict = defaultdict(set)

	# Populate DefaultDict
	for dKey, dSet in inputDict.items():
		tempDict[dKey] = dSet

	# Generate Statistics
	typeFlag = False
	taxaFlag = False
	seriesTypeSet = tempDict['Series_type']
	seriesTaxonSet = tempDict['Series_sample_organism']

	if len(seriesTypeSet) < 1 or len(seriesTaxonSet) < 1:
		continue

	for stElem in seriesTypeSet:
		if stElem in ['Expression profiling by array', 'Expression profiling by high throughput sequencing']:
			typeFlag = True

	for stElem in seriesTaxonSet:
		if stElem in ['Homo sapiens', 'Mus musculus', 'Rattus norvegicus'] and typeFlag:
			taxaFlag = True

	resultDict['array_and_seq'] += int(typeFlag)
	resultDict['array_and_seq_and_tri_taxa'] += int(taxaFlag)

# Statistics Reporter
print('# Microarray/RNA-Seq: {0}'.format(resultDict['array_and_seq']))
print('# Microarray/RNA-Seq + Human/Mouse/Rat: {0}'.format(resultDict['array_and_seq_and_tri_taxa']))

# Time Reporter
print(globalTimer.getEndStamp())
