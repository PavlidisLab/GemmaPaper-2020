# Discussion-Section Information (2)

# Set Working Directory

# Load Libraries
require(data.table)

# Declaring Global Variables
archsDir = 'Dependencies/ARCHS4/'
outDir = 'ROutput/'

options(
	stringsAsFactors = FALSE,
	warn = 1
)

# Global Preparation ------------------------------------------------------
# Creation of Output Directory
dir.create(outDir, recursive = TRUE, showWarnings = FALSE)

# Creation of Output Log
outLogPath = sprintf('%sDISCUSSION_2.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted) & ee.IsPublic]

humanARCHS4.env = new.env()
tempPath = sprintf('%shuman_gsm_meta.rda', archsDir)
load(file = tempPath, envir = humanARCHS4.env)
humanARCHS4.vector = unlist(sapply(humanARCHS4.env$gsmMeta, function(i) {i$Sample_series_id}), use.names = FALSE)

mouseARCHS4.env = new.env()
tempPath = sprintf('%smouse_gsm_meta.rda', archsDir)
load(file = tempPath, envir = mouseARCHS4.env)
mouseARCHS4.vector = unlist(sapply(mouseARCHS4.env$gsmMeta, function(i) {i$Sample_series_id}), use.names = FALSE)

archs4Vector = unique(c(humanARCHS4.vector, mouseARCHS4.vector))
rm(humanARCHS4.env, humanARCHS4.vector, mouseARCHS4.env, mouseARCHS4.vector)

# ----- Generate Statistics/Plots -----

# [R1] ARCHS4 EE-Count -----
reportVal_ARCHS_N_GSE = length(archs4Vector)
reportVal_ARCHS_N_EE = eeMetadata[archs4Vector, uniqueN(ee.OriginalID), on = 'ee.OriginalID', nomatch = 0]

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# ARCHS4 GSE: %s\n', reportVal_ARCHS_N_GSE),
	sprintf('# ARCHS4 EE in Gemma: %s\n', reportVal_ARCHS_N_EE),
	file = outLogPath,
	sep = '',
	append = TRUE
)