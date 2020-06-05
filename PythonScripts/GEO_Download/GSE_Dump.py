# GEO Metadata Bulk Downloader (GSE: Series)
# 1. Generates Metadata Dictionaries of GSE-SOFT Files

# Python imports
import argparse
import os
import requests
import re
from ftplib import FTP
from datetime import datetime
from PyVersion import PyCheckLenient
from ElapseTime import ElapseTime
from XZPickle import XZWrite

# Python Version Check
# Requirement: CPython 3.7.X
assert PyCheckLenient('CPython', '3', '7')

# CLI Generation and Parsing
cliParser = argparse.ArgumentParser()
cliParser.add_argument('-c', required = False, default = False, action = 'store_true', help = 'Clear data cache')
cliParser.add_argument('-n', required = False, default = None, type = int, help = 'Download N entries; integer-type')
cliOpts = cliParser.parse_args()

# Declaring Global Variables
os.chdir('{0}/GeoData/GSE/'.format(os.getenv('DL_CACHE_DIR')))
ftpPath = '/geo/series/'
globalTimer = ElapseTime()
print(globalTimer.getBeginStamp())

# ------------------------------ MAIN ------------------------------
# Clear Cache
if cliOpts.c:
	print('Emptying Cache [-c flag]')
	cacheFiles = os.listdir()
	for everyFile in cacheFiles:
		os.remove(everyFile)

# Print Limit
if cliOpts.n is not None:
	print('Entry Limit: {0} [-n flag]'.format(cliOpts.n))

# Parse FTP Directory (Multi-Step to Avoid Timeout)
safeDeleteFlag = True
entryList = []

# 1. Obtain Directories
print('Loading Parent Directory', flush = True)
with FTP('ftp.ncbi.nlm.nih.gov', timeout = 300) as ftp:
	ftp.login()
	ftp.cwd(dirname = ftpPath)
	dirList = list(filter(lambda x: re.match(pattern = '^GSE[0-9]*nnn$', string = x), ftp.nlst()))
	ftp.quit()

# 2. Obtain Entries
print('Obtaining Individual Entries', flush = True)
dirList.sort()
for dirIndex, dirName in enumerate(dirList, start = 1):
	if dirIndex % 20 == 0:
		print('Parsed: {0} / {1}'.format(dirIndex, len(dirList)), flush = True)

	retryCount = 0
	loopFlag = True
	while loopFlag:
		if retryCount == 3:
			loopFlag = False
			safeDeleteFlag = False
			print('ERROR: Directory {0} could not be processed'.format(dirName), flush = True)
			continue

		elif retryCount > 0:
			print('WARN: Retrieval repeat for directory {0}'.format(dirName))

		try:
			with FTP('ftp.ncbi.nlm.nih.gov', timeout = 420) as ftp:
				ftp.login()
				ftp.cwd(dirname = '{0}{1}'.format(ftpPath, dirName))
				subdirList = filter(lambda x: re.match(pattern = '^GSE[0-9]+$', string = x), ftp.nlst())
				entryList.extend(subdirList)
				ftp.quit()
			loopFlag = False

		except:
			retryCount += 1

del dirList
print('Total Entries: {0}'.format(len(entryList)))

# Delete Non-existent Files (If Safe)
if safeDeleteFlag:
	print('Trimming Cache')
	cacheFiles = os.listdir()
	for everyFile in cacheFiles:
		if everyFile.rstrip('.DICT.XZ') not in entryList:
			os.remove(everyFile)
else:
	print('WARNING: Cache trimming skipped due to failed FTP processing')

# Download and Parse SOFT Files
print('Downloading SOFT Files', flush = True)
requestCounter = 0
failCounter = 0
for entryIndex, everyEntry in enumerate(entryList, start = 1):
	tempPath = '{0}.DICT.XZ'.format(everyEntry)

	if cliOpts.n is not None and requestCounter == cliOpts.n:
		print('N-limit reached. Download halted.')
		break

	if entryIndex % 2500 == 0:
		print('Downloaded: {0}; Processed: {1:.1%}'.format(requestCounter, entryIndex/len(entryList)), flush = True)

	# Skip If Exist AND Within Expiry (< 6 Months/180 Days)
	if os.path.lexists(tempPath):
		timeDiff = datetime.now() - datetime.fromtimestamp(os.path.getmtime(tempPath))
		if timeDiff.days < 180:
			continue

	tempLink = 'https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi'
	linkOptions = {
		'acc': everyEntry,
		'targ': 'self',
		'form': 'text',
		'view': 'brief'
	}

	# Obtain SOFT File, Skips on Exception
	try:
		tempRequest = requests.get(tempLink, params = linkOptions, timeout = 60)
		requestCounter += 1

	except:
		failCounter += 1
		print('FAIL: {0}'.format(everyEntry), flush = True)
		continue

	# SOFT -> DICT Conversion
	tempDict = dict()
	responseList = tempRequest.text.splitlines()
	for everyLine in responseList:
		# Skip if NO '!' Prefix
		if not everyLine.startswith('!'):
			continue

		tempList = everyLine.lstrip('!').partition(' = ')

		if tempList[2] != '':
			if tempList[0] not in tempDict:
				tempDict[tempList[0]] = set()
			tempDict[tempList[0]].add(tempList[2])

	# Write To File (Protocol = 2 for Jython-compatibility)
	tempPath = '{0}.DICT.XZ'.format(everyEntry)
	XZWrite(obj = tempDict, path = tempPath, protocol = 2)

# Diagnostics
print('-' * 20)
print('Number of new entries processed: {0}'.format(requestCounter))
print('Number of failed downloads: {0}'.format(failCounter))

# Time Reporter
print(globalTimer.getEndStamp())
