# EBI-GXA FTP Metadata Parser
# 1. Generate Statistical Counts of GXA Experiments

# Python imports
import os
from ftplib import FTP
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime

# Python Version Check
# Requirement: CPython 3.7.X
assert PyCheckLenient('CPython', '3', '7')

# Declaring Global Variables
outputPath = '{0}/GXA_GSE_List.TXT'.format(os.getenv('OUT_DIR'))
ftpPath = '/pub/databases/microarray/data/atlas/experiments/'
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# ------------------------------ MAIN ------------------------------
# Parse FTP Directory
print('Loading Parent Directory')
entrySet = set()


# Custom Function For Handling FTP.LIST Output
def listFilter(inputString):
	# Skip Non-Directory Objects
	if not inputString.startswith('d'):
		return None

	tempList = inputString.split(' ')
	entrySet.add(tempList[-1])


with FTP('ftp.ebi.ac.uk', timeout = 3600) as ftp:
	ftp.login()
	ftp.cwd(ftpPath)
	tempOutput = ftp.retrlines(cmd = 'LIST', callback = listFilter)
	if tempOutput.startswith('226'):
		pass
	else:
		print('ERROR: {0}'.format(tempOutput))
	ftp.quit()

# Parsing Experiment List for GSE
gseSet = set()
for entryElem in entrySet:
	if entryElem.startswith('E-GEOD'):
		gseSet.add('GSE{0}'.format(entryElem.rsplit('-')[-1]))

# Write To File
with open(file = outputPath, mode = 'wt', newline = '\n') as outFile:
	outFile.write('\n'.join(sorted(gseSet)))

# Time Reporter
print(globalTimer.getEndStamp())
