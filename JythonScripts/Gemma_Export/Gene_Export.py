# Gemma Export Script: Gene Metadata

# Python Imports
from __future__ import print_function
import argparse
import os
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from StrUtils import FormatASCII
from SpringSupport import SpringSupport
from XZPickle import XZRead

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
geneDetailsPath = os.getenv('GENE_DIR')
taxonTuple = ('human', 'mouse', 'rat', 'zebrafish', 'fly', 'worm', 'yeast')

# Logging Processing Time
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# Start Spring Session and Service Declarations
sx = SpringSupport(cliOpts.u, cliOpts.p)
taxonService = sx.getBean('taxonService')
geneService = sx.getBean('geneService')

# ------------------------------ MAIN ------------------------------
# Credentials Check
if not SecurityUtil.isUserAdmin():
	print('ERROR: Administrative privileges required.')
	raise RuntimeError('Administrative privileges required.')

# Creating Metadata File Handle
metadataFileHandle = open(name = 'Gene_Export.TSV', mode = 'wt')

# Prepare Metadata Header
metaHeader = ['gene.Taxon', 'gene.ID', 'gene.EntrezID', 'gene.Type']
metaHeader.extend(['gene.NumCS', 'gene.NumAD'])
metadataFileHandle.write('\t'.join(metaHeader) + '\n')

print('Generating Gene Metadata')
for taxon in taxonTuple:
	geneList = geneService.loadAll(taxonService.findByCommonName(taxon))

	# Load Gene Info Dictionary
	tempPath = '{0}/GeneType/geneType.{1}.DICT.XZ'.format(geneDetailsPath, taxon)
	geneInfoDict = XZRead(tempPath)

	for gene in geneList:
		gene = geneService.thawLite(gene)
		gvo = geneService.loadFullyPopulatedValueObject(Long(gene.id))

		# Gene Type Details
		geneType = 'NA'
		if gene.ncbiGeneId in geneInfoDict:
			geneType = geneInfoDict[gene.ncbiGeneId]

		tempList = [taxon, gene.id, gene.ncbiGeneId, geneType]
		tempList.extend([gvo.compositeSequenceCount, gvo.platformCount])

		tempList = map(FormatASCII, tempList)
		metadataFileHandle.write('\t'.join(tempList) + '\n')

# Time Reporter
print(globalTimer.getEndStamp())

# Close File Handles
metadataFileHandle.close()

# End Spring Session
sx.shutDown()
