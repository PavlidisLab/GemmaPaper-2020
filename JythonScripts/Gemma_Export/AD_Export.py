# Gemma Export Script: Platform Metadata

# Python Imports
from __future__ import print_function
import argparse
import os
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from StrUtils import FormatASCII
from SpringSupport import SpringSupport

# Java Imports
from gemma.gsec.util import SecurityUtil
from java.lang import Long

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')

# CLI Generation and Parsing
cliParser = argparse.ArgumentParser()
cliParser.add_argument('-u', required = False, default = None, help = 'Gemma username')
cliParser.add_argument('-p', required = False, default = None, help = 'Gemma password')
cliOpts = cliParser.parse_args()

# Declaring Global Variables
os.chdir(os.getenv('OUT_DIR'))

# Logging Processing Time
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# Start Spring Session and Service Declarations
sx = SpringSupport(cliOpts.u, cliOpts.p)
platformService = sx.getBean('arrayDesignService')
experimentService = sx.getBean('expressionExperimentService')
sequenceService = sx.getBean('compositeSequenceService')

# ------------------------------ MAIN ------------------------------
# Credentials Check
if not SecurityUtil.isUserAdmin():
	print('ERROR: Administrative privileges required.')
	raise RuntimeError('Administrative privileges required.')

# Loading Sequence-Corrected Gene Type Dictionary
centralGeneTypeDict = dict()
for taxon in ['human', 'mouse', 'rat', 'zebrafish', 'fly', 'worm', 'yeast']:
	centralGeneTypeDict[taxon] = set()
with open('Gene_Export.TSV', mode = 'rt') as geneFile:
	for lineIndex, everyLine in enumerate(geneFile):
		# Skip Header
		if lineIndex == 0:
			continue
		tempArray = everyLine.strip('\n').split('\t')

		# Populate Gene Set
		if tempArray[3] == 'protein-coding' and int(tempArray[4]) > 0:
			centralGeneTypeDict[tempArray[0]].add(int(tempArray[2]))

# Creating Metadata File Handle
metadataFileHandle = open(name = 'AD_Export.TSV', mode = 'wt')

# Prepare Metadata Header
metaHeader = ['ad.ID', 'ad.Name', 'ad.Title', 'ad.IsTroubled', 'ad.IsBlacklisted']
metaHeader.extend(['ad.Taxon', 'ad.TechType', 'ad.IsAltAffy', 'ad.IsMerged'])
metaHeader.extend(['ad.NumEE', 'ad.NumProbe', 'ad.NumGene', 'ad.NumProtGene', 'ad.RatioProtGene'])
metadataFileHandle.write('\t'.join(metaHeader) + '\n')

print('Generating Platform Metadata.')
adList = platformService.loadAllValueObjects()

for adIndex, advo in enumerate(adList):
	ad = platformService.load(advo.id)

	# Load Gene Type Dictionary
	geneTypeSet = set()
	totalPCGene = 0
	if ad.primaryTaxon.commonName in ['human', 'mouse', 'rat', 'zebrafish', 'fly', 'worm', 'yeast']:
		geneTypeSet = centralGeneTypeDict[ad.primaryTaxon.commonName]
		totalPCGene = len(geneTypeSet)

	# Troubled State
	adTroubled = ad.curationDetails.troubled

	# Blacklisted State
	adBlacklisted = platformService.isBlackListed(ad.shortName)

	# Merged State
	adMerged = platformService.isMerged([Long(ad.id)]).values()[0]

	# Experiment and Sample Count
	adNumEE = 0
	for ee in platformService.getExpressionExperiments(ad):
		eevo = experimentService.loadValueObject(ee)
		if eevo.isPublic and not experimentService.isTroubled(ee):
			adNumEE += 1

	# Probe/Gene Counts
	adNumProbe = platformService.getCompositeSequenceCount(ad)
	adNumGene = platformService.numGenes(ad)

	# Protein-Coding Gene Counts and Ratios
	probeSet = platformService.getCompositeSequences(ad)
	finalGeneSet = set()
	for probe, tempGeneSet in sequenceService.getGenes(probeSet).iteritems():
		tempGeneSet = filter(lambda x: x is not None, tempGeneSet)
		if len(tempGeneSet) > 0:
			finalGeneSet.update(map(lambda x: x.ncbiGeneId, tempGeneSet))

	adNumPCGene = 0
	for gene in finalGeneSet:
		if gene in geneTypeSet:
			adNumPCGene += 1

	adRatioPCGene = 'NA'
	if totalPCGene > 0:
		adRatioPCGene = float(adNumPCGene)/float(totalPCGene)

	tempList = [advo.id, advo.shortName, advo.name, adTroubled, adBlacklisted]
	tempList.extend([ad.primaryTaxon.commonName, ad.technologyType.value, advo.isAffymetrixAltCdf, adMerged])
	tempList.extend([adNumEE, adNumProbe, adNumGene, adNumPCGene, adRatioPCGene])

	tempList = map(FormatASCII, tempList)
	metadataFileHandle.write('\t'.join(tempList) + '\n')

# Time Reporter
print(globalTimer.getEndStamp())

# Close File Handles
metadataFileHandle.close()

# End Spring Session
sx.shutDown()
