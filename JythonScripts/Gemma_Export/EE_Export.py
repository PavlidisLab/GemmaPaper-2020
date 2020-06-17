# Gemma Export Script: Experimental Metadata

# Python Imports
from __future__ import print_function
import argparse
import os
from array import array
from math import isnan, isinf
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from StrUtils import FormatASCII
from MathUtils import Median
from SpringSupport import SpringSupport

# Java Imports
from gemma.gsec.util import SecurityUtil
from ubic.gemma.core.analysis.preprocess.batcheffects import BatchConfound

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
experimentService = sx.getBean('expressionExperimentService')
correlationService = sx.getBean('sampleCoexpressionAnalysisService')

# ------------------------------ MAIN ------------------------------
# Credentials Check
if not SecurityUtil.isUserAdmin():
	print('ERROR: Administrative privileges required.')
	raise RuntimeError('Administrative privileges required.')

# Creating Metadata File Handle
metadataFileHandle = open(name = 'EE_Export.TSV', mode = 'wt')

# Prepare Metadata Header
metaHeader = ['ee.ID', 'ee.Name', 'ee.OriginalID', 'ee.Source', 'ee.IsPublic', 'ee.IsTroubled', 'ee.IsBlacklisted']
metaHeader.extend(['ee.Taxon', 'ee.NumSample', 'ee.NumOutlier', 'ee.PMID'])
metaHeader.extend(['ee.QualityScore', 'ee.MedianCor', 'ee.IsReprocessed'])
metaHeader.extend(['ee.HasBatch', 'ee.BatchEffected', 'ee.IsCorrected', 'ee.IsConfounded'])
metaHeader.extend(['ad.ID', 'ad.Name', 'ad.Num', 'ad.Type', 'ad.Company'])
metadataFileHandle.write('\t'.join(metaHeader) + '\n')

print('Generating Experiment Metadata')
eeList = experimentService.loadAllValueObjects()

for eevo in eeList:
	ee = experimentService.thawLite(experimentService.load(eevo.id))
	qtList = experimentService.getQuantitationTypes(ee)

	# Original IDs
	eeAccession = 'NA'
	if ee.accession is not None:
		eeAccession = ee.accession.accession

	# Source Details
	eeSource = 'Manual'
	if eevo.externalDatabase in ['GEO', 'ArrayExpress']:
		eeSource = eevo.externalDatabase

	# Troubled State (Incl. Platform Check)
	eeTroubled = experimentService.isTroubled(ee)

	# Blacklisted State
	eeBlacklisted = experimentService.isBlackListed(eeAccession)

	# Taxon Details
	eeTaxon = experimentService.getTaxon(ee).commonName

	# Sample Details
	nSample = experimentService.getBioMaterialCount(ee)

	# Outlier Details
	nOutlier = set()
	for ba in ee.bioAssays:
		if ba.isOutlier:
			nOutlier.add(ba.sampleUsed.id)
	nOutlier = len(nOutlier)

	# PMID Details
	eePMID = 'NA'
	if ee.primaryPublication is not None:
		eePMID = ee.primaryPublication.pubAccession.accession

	# GEEQ Scores
	eeGeeq = 'NA'
	if eevo.geeq is not None:
		eeGeeq = eevo.geeq.publicQualityScore

	# Sample Correlation (Regressed) Details
	eeCor = 'NA'
	try:
		corMatrix = correlationService.loadTryRegressedThenFull(ee).asArray()
		corVector = array('d')

		for matIndex, matSlice in enumerate(corMatrix, start = 1):
			corVector.extend(matSlice[matIndex:])
		corVector = filter(lambda x: not (isnan(x) or isinf(x)), corVector)
	except:
		corVector = []
	if len(corVector) > 0:
		eeCor = Median(corVector)

	# Reprocessed State
	eeReprocess = any(map(lambda x: x.isRecomputedFromRawData, qtList))

	# Batch Details
	batchList = [False] * 4
	if experimentService.checkHasBatchInfo(ee):
		beDetails = experimentService.getBatchEffect(ee)
		eeConfounded = False

		if beDetails.pvalue < 0.01:
			try:
				bcDetails = BatchConfound.test(ee)
			except:
				bcDetails = []
			if len(bcDetails) > 0:
				eeConfounded = min(map(lambda x: x.p, bcDetails)) < 0.01

		batchList = [
			True,
			beDetails.pvalue < 0.01,
			beDetails.dataWasBatchCorrected,
			eeConfounded
		]

	# Platform Details
	adList = sorted(experimentService.getArrayDesignsUsed(ee))
	adIDVector = map(lambda x: FormatASCII(x.id), adList)
	adNameVector = map(lambda x: FormatASCII(x.shortName), adList)
	adTechVector = set(map(lambda x: FormatASCII(x.technologyType.value), adList))
	adTitle = ';'.join(map(lambda x: FormatASCII(x.name), adList)).lower()
	adCompany = 'NA'
	if 'affymetrix' in adTitle:
		adCompany = 'Affymetrix'
	elif 'illumina' in adTitle:
		adCompany = 'Illumina'
	elif 'agilent' in adTitle:
		adCompany = 'Agilent'
	finalADList = [
		'; '.join(adIDVector),
		'; '.join(adNameVector),
		len(adList),
		'; '.join(adTechVector),
		adCompany
	]

	tempList = [eevo.id, eevo.shortName, eeAccession, eeSource, eevo.isPublic, eeTroubled, eeBlacklisted]
	tempList.extend([eeTaxon, nSample, nOutlier, eePMID])
	tempList.extend([eeGeeq, eeCor, eeReprocess])
	tempList.extend(batchList)
	tempList.extend(finalADList)

	tempList = map(FormatASCII, tempList)
	metadataFileHandle.write('\t'.join(tempList) + '\n')

# Time Reporter
print(globalTimer.getEndStamp())

# Close File Handles
metadataFileHandle.close()

# End Spring Session
sx.shutDown()
