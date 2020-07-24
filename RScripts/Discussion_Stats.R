# Discussion-Section Information

# Set Working Directory

# Load Libraries
require(data.table)

# Declaring Global Variables
outDir = 'ROutput/'

options(
	stringsAsFactors = FALSE,
	warn = 1
)

# Global Preparation ------------------------------------------------------
# Creation of Output Directory
dir.create(outDir, recursive = TRUE, showWarnings = FALSE)

# Creation of Output Log
outLogPath = sprintf('%sDISCUSSION.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
gxaVector = readLines(con = 'GXA_GSE_List.TXT', warn = FALSE)
gpaDT = fread('GPA.DT.TSV', sep = '\t', header = TRUE)

eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted) & ee.IsPublic]

# ----- Generate Statistics/Plots -----

# [R1] GXA EE-Count -----
gxaVector = unique(gxaVector)
reportVal_GXA_N_GSE = length(gxaVector)
reportVal_GXA_N_EE = eeMetadata[gxaVector, uniqueN(ee.OriginalID), on = 'ee.OriginalID', nomatch = 0]

# [R2] GPA EE and GSE-Count -----
gpaVector = unique(gpaDT[, GSE.ID])
reportVal_GPA_N_GSE = length(gpaVector)
reportVal_GPA_N_EE = eeMetadata[gpaVector, uniqueN(ee.OriginalID), on = 'ee.OriginalID', nomatch = 0]

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# GXA GSE: %s\n', reportVal_GXA_N_GSE),
	sprintf('# GXA EE in Gemma: %s\n', reportVal_GXA_N_EE),
	
	sprintf('# GPA GSE: %s\n', reportVal_GPA_N_GSE),
	sprintf('# GPA EE in Gemma: %s\n', reportVal_GPA_N_EE),
	file = outLogPath,
	sep = '',
	append = TRUE
)