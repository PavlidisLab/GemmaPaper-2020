# Gemma Dump Script: Ontology Tree

# Python Imports
from __future__ import print_function
import argparse
import os
import time
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from SpringSupport import SpringSupport
from OntologyUtils import GemmaOntTerm

# Java Imports
from gemma.gsec.util import SecurityUtil

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')

# CLI Generation and Parsing
cliParser = argparse.ArgumentParser()
cliParser.add_argument('-u', required = False, default = None, help = 'Gemma username')
cliParser.add_argument('-p', required = False, default = None, help = 'Gemma password')
cliOpts = cliParser.parse_args()

# Declaring Global Variables
os.chdir('{0}/Ontology/'.format(os.getenv('DATA_CACHE_DIR')))

# Logging Processing Time
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# Start Spring Session and Service Declarations
sx = SpringSupport(cliOpts.u, cliOpts.p)
ontologyService = sx.getBean('ontologyService')

# ------------------------------ MAIN ------------------------------
# Credentials Check
if not SecurityUtil.isUserAdmin():
	print('ERROR: Administrative privileges required.')
	raise RuntimeError('Administrative privileges required.')

# Load Ontologies
ontologyList = [
	['GO', sx.getBean('geneOntologyService')],
	['CLO', ontologyService.cellLineOntologyService],
	['CL', ontologyService.cellTypeOntologyService],
	['CHEBI', ontologyService.chebiOntologyService],
	['DO', ontologyService.diseaseOntologyService],
	['EFO', ontologyService.experimentalFactorOntologyService],
	['TGEMO', ontologyService.gemmaOntologyService],
	['HP', ontologyService.humanPhenotypeOntologyService],
	['MP', ontologyService.mammalianPhenotypeOntologyService],
	['OBI', ontologyService.obiService],
	['UBERON', ontologyService.uberonService]
]

serviceFlag = True
restartCounter = 0
while serviceFlag and restartCounter < 360:
	serviceList = []

	for ontName, ontEngine in ontologyList:
		if ontName == 'GO':
			serviceList.append(ontEngine.ready)
		else:
			serviceList.append(ontEngine.ontologyLoaded)

	serviceFlag = not all(serviceList)
	if serviceFlag:
		# Wait For Ontology Loading
		time.sleep(30)
		restartCounter += 1

	if restartCounter >= 360:
		# Ontology Load Failure (3 hours)
		raise RuntimeError('ERROR: Unable to successfully load ontologies.')

del serviceFlag, serviceList

# Create Merged File Handle
mergeTreeFileHandle = open(name = 'Ontology_Dump_MERGED.TSV', mode = 'wt')
treeHeader = ['ChildNode', 'ParentNode', 'ChildNode_Long', 'ParentNode_Long', 'RelationType', 'OntologyScope']
mergeTreeFileHandle.write('\t'.join(treeHeader) + '\n')

mergeDefFileHandle = open(name = 'Ontology_Dump_MERGED_DEF.TSV', mode = 'wt')
defHeader = ['Node', 'Node_Long', 'Definition', 'OntologyScope']
mergeDefFileHandle.write('\t'.join(defHeader) + '\n')

print('Exporting Ontology Trees.')
for ontName, ontEngine in ontologyList:
	print('Currently Processing: {0}'.format(ontName))

	# Create Individual File Handle
	currentTreeFileHandle = open(name = 'Ontology_Dump_{0}.TSV'.format(ontName), mode = 'wt')
	currentTreeFileHandle.write('\t'.join(treeHeader) + '\n')

	currentDefFileHandle = open(name = 'Ontology_Dump_{0}_DEF.TSV'.format(ontName), mode = 'wt')
	currentDefFileHandle.write('\t'.join(defHeader) + '\n')

	# Node Tracker
	nodeTrackerDict = dict()

	# Obtain Ontology Terms
	if ontName == 'GO':
		ontologySet = set(ontEngine.listTerms())
	else:
		ontologySet = set(map(lambda URI: ontEngine.getTerm(URI), ontEngine.allURIs))

	for ontology in ontologySet:
		# Obsolescence Check
		if ontology.termObsolete:
			continue

		# Invalid Identifier Check
		if ontology.uri is None:
			continue

		# Populate Definition
		gemmaTerm = GemmaOntTerm(ontology)
		if gemmaTerm.termURI not in nodeTrackerDict:
			nodeTrackerDict[gemmaTerm.termURI] = gemmaTerm

		# Process Parent Nodes
		parentList = ontology.getParents(True)

		if len(parentList) > 0:
			for parentNode in parentList:
				# Obsolescence Check
				if parentNode.termObsolete:
					continue

				# Invalid Identifier Check
				if parentNode.uri is None:
					continue

				# Populate Definition
				termParent = GemmaOntTerm(parentNode)
				if termParent.termURI not in nodeTrackerDict:
					nodeTrackerDict[termParent.termURI] = termParent

				# Populate Relationship + Write To File
				tempList = [
					gemmaTerm.shortURI, termParent.shortURI,
					gemmaTerm.termURI, termParent.termURI,
					'is_a', ontName
				]
				mergeTreeFileHandle.write('\t'.join(tempList) + '\n')
				currentTreeFileHandle.write('\t'.join(tempList) + '\n')

		# Process Children Nodes (part_of Restrictions)
		restrictionList = ontology.restrictions

		if len(restrictionList) > 0:
			for restriction in restrictionList:
				# Relevance Check
				if restriction.restrictionOn.label != 'part of':
					continue

				# Obsolescence Check
				if restriction.restrictedTo.termObsolete:
					continue

				# Invalid Identifier Check
				if restriction.restrictedTo.uri is None:
					continue

				# Populate Definition
				termParent = GemmaOntTerm(restriction.restrictedTo)
				if termParent.termURI not in nodeTrackerDict:
					nodeTrackerDict[termParent.termURI] = termParent

				# Populate Relationship + Write To File
				tempList = [
					gemmaTerm.shortURI, termParent.shortURI,
					gemmaTerm.termURI, termParent.termURI,
					'part_of', ontName
				]
				mergeTreeFileHandle.write('\t'.join(tempList) + '\n')
				currentTreeFileHandle.write('\t'.join(tempList) + '\n')

		# Process Children Nodes (has_role Restrictions; CHEBI-specific)
		restrictionList = ontology.restrictions

		if len(restrictionList) > 0 and ontName == 'CHEBI':
			for restriction in restrictionList:
				# Relevance Check
				if restriction.restrictionOn.label != 'has role':
					continue

				# Obsolescence Check
				if restriction.restrictedTo.termObsolete:
					continue

				# Invalid Identifier Check
				if restriction.restrictedTo.uri is None:
					continue

				# Populate Definition
				termParent = GemmaOntTerm(restriction.restrictedTo)
				if termParent.termURI not in nodeTrackerDict:
					nodeTrackerDict[termParent.termURI] = termParent

				# Populate Relationship + Write To File
				tempList = [
					gemmaTerm.shortURI, termParent.shortURI,
					gemmaTerm.termURI, termParent.termURI,
					'has_role', ontName
				]
				mergeTreeFileHandle.write('\t'.join(tempList) + '\n')
				currentTreeFileHandle.write('\t'.join(tempList) + '\n')

	# Definition: Write To File
	for gemmaTerm in nodeTrackerDict.values():
		tempList = [gemmaTerm.shortURI, gemmaTerm.termURI, gemmaTerm.termValue, ontName]
		mergeDefFileHandle.write('\t'.join(tempList) + '\n')
		currentDefFileHandle.write('\t'.join(tempList) + '\n')

	# Close File Handles
	currentTreeFileHandle.close()
	currentDefFileHandle.close()

# Time Reporter
print(globalTimer.getEndStamp())

# Close File Handles
mergeTreeFileHandle.close()
mergeDefFileHandle.close()

# End Spring Session
sx.shutDown()
