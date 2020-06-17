# Gemma Export Script: Experimental Tag Metadata

# Python Imports
from __future__ import print_function
import argparse
import os
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from StrUtils import FormatASCII
from SpringSupport import SpringSupport
from OntologyUtils import ExperimentTagList

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
experimentService = sx.getBean('expressionExperimentService')

# ------------------------------ MAIN ------------------------------
# Credentials Check
if not SecurityUtil.isUserAdmin():
	print('ERROR: Administrative privileges required.')
	raise RuntimeError('Administrative privileges required.')

# Creating Metadata File Handle
metadataFileHandle = open(name = 'EETag_Export.TSV', mode = 'wt')

# Prepare Metadata Header
metaHeader = ['ee.ID', 'et.Val', 'et.ValUri', 'et.ValShortURI', 'et.Type', 'et.Evidence']
metadataFileHandle.write('\t'.join(metaHeader) + '\n')

print('Generating Experiment Metadata')
eeList = experimentService.loadAllValueObjects()

for eevo in eeList:
	eeAnnotList = ExperimentTagList(experimentService.getAnnotations(Long(eevo.id)))

	for eeAnnot in eeAnnotList.list:
		tempList = [eevo.id, eeAnnot.termValue.termValue, eeAnnot.termValue.termURI, eeAnnot.termValue.shortURI]
		tempList.extend([eeAnnot.termType, eeAnnot.evidence])

		tempList = map(FormatASCII, tempList)
		metadataFileHandle.write('\t'.join(tempList) + '\n')

# Time Reporter
print(globalTimer.getEndStamp())

# Close File Handles
metadataFileHandle.close()

# End Spring Session
sx.shutDown()
