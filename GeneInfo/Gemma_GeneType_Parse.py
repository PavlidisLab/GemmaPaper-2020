# Gene Info Annotation Parser (Gene Type):
# 1. Generation of EntrezID: (Gene Type) Dictionary for Python

# Python Imports
from PyVersion import PyCheckLenient
import os
from IterUtils import RSlice
from XZPickle import XZWrite

# Python Version Check
# Requirement: CPython 3.7.X
assert PyCheckLenient('CPython', '3', '7')

# Declaring Global Variables
inPath = '{0}/gene_info'.format(os.getenv('IN_DIR'))
outDir = '{0}/GeneType/'.format(os.getenv('OUT_DIR'))
taxonList = [
	('human', '9606'),
	('mouse', '10090'),
	('rat', '10116'),
	('zebrafish', '7955'),
	('fly', '7227'),
	('worm', '6239'),
	('yeast', '4932')
]
taxonTuple = tuple(map(lambda x: x[1], taxonList))

# ------------------------------ MAIN ------------------------------
tupleSet = set()
print('Processing Annotation File.')
with open(inPath, mode = 'rt', encoding = 'utf-8', newline = '\n') as inFile:
	for everyLine in inFile:
		# Skip Header
		if everyLine.startswith('#'):
			continue

		everyLine = everyLine.strip('\n')
		tempArray = everyLine.split('\t')

		# Skip Irrelevant Taxon
		if tempArray[0] not in taxonTuple:
			continue
		else:
			tempTuple = tuple(RSlice(tempArray, [0, 1, 9]))
			tupleSet.add(tempTuple)

for taxon, taxonID in taxonList:
	print('Sorting: {0}'.format(taxon))

	# Filter Tuples By Taxon, Add To Dictionary
	finalDict = dict()
	for (currentTaxon, currentGene, currentType) in tupleSet:
		if currentTaxon == taxonID:
			finalDict[int(currentGene)] = currentType

	# Sorted List of GeneID
	finalList = sorted(finalDict.items(), key = lambda x: x[0])

	# Write To File
	print('Writing Files.')

	# 1. Python Dictionary (XZ-Backed, Protocol 2 for Jython-compatibility)
	tempPath = '{0}geneType.{1}.DICT.XZ'.format(outDir, taxon)
	XZWrite(obj = finalDict, path = tempPath, protocol = 2)
