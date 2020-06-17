# Experiment Tag-Level Plots (1: General Statistics)

# Set Working Directory

# Load Libraries
require(data.table)

# Declaring Global Variables
outDir = 'ROutput/'
targetTaxon = c('human', 'mouse', 'rat')

options(
	stringsAsFactors = FALSE,
	warn = 1
)

# Global Preparation ------------------------------------------------------
# Creation of Output Directory
dir.create(outDir, recursive = TRUE, showWarnings = FALSE)

# Creation of Output Log
outLogPath = sprintf('%sEETag_1.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
tagMetadata = fread('EETag_Export.TSV', sep = '\t', header = TRUE)

eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted | is.na(ee.Taxon)) & ee.IsPublic]
tagMetadata = tagMetadata[eeMetadata[, .(ee.ID)], on = 'ee.ID', nomatch = 0]
tempTaxonVector = eeMetadata[tagMetadata[, .(ee.ID)], ee.Taxon, on = 'ee.ID']
tagMetadata[, ee.Taxon := tempTaxonVector]
rm(tempTaxonVector)

# ----- Generate Statistics/Plots -----
# (Pre-Taxon Filter) -----
# [R1] Tag-Count -----
reportVal_N_Tag_ALL = nrow(tagMetadata)

# (Post-Taxon Filter) -----
tagMetadata = tagMetadata[targetTaxon, on = 'ee.Taxon']

# [R2] Tag-Count (Human, Mouse, Rat) -----
reportVal_N_Tag_HMR = nrow(tagMetadata)

# [R3] (HMR) Ontology Term-Count & Unique Term-Count; Unique Free-Text Term-Count -----
reportVal_N_Ontology = tagMetadata[!is.na(et.ValShortURI), .N]
reportVal_uniqueN_Ontology = tagMetadata[!is.na(et.ValShortURI), uniqueN(et.ValShortURI)]
reportVal_uniqueN_FreeText = tagMetadata[is.na(et.ValShortURI), uniqueN(et.Val)]

# [TABLE-1] (HMR) Tag Type-Count -----
tempDT = tagMetadata[, .N, et.Type]

cat(
	'\n\n----- # Tag By Type -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R4] (HMR) Tag "IC" Evidence-Count -----
reportVal_N_IC = tagMetadata[c('IC', ''), .N, on = 'et.Evidence']

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# Tags (ALL): %s\n', reportVal_N_Tag_ALL),
	sprintf('# Tags (H,M,R): %s\n', reportVal_N_Tag_HMR),
	sprintf('# Tags (Ontology Term; HMR): %s\n', reportVal_N_Ontology),
	sprintf('# Tags (Unique Ont; HMR): %s\n', reportVal_uniqueN_Ontology),
	sprintf('# Tags (Unique Free-Text; HMR): %s\n', reportVal_uniqueN_FreeText),
	sprintf('# Tags (Evidence: IC; HMR): %s\n', reportVal_N_IC),
	file = outLogPath,
	sep = '',
	append = TRUE
)