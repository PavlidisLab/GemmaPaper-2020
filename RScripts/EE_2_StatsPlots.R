# Experiment-Level Plots (2: Data Quality)

# Set Working Directory

# Load Libraries
require(data.table)
require(ggplot2)
require(cowplot)

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
outLogPath = sprintf('%sEE_2.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted) & ee.IsPublic]
eeMetadata = eeMetadata[targetTaxon, on = 'ee.Taxon']

# ----- Generate Statistics/Plots -----

# 1. Median Sample-Correlation -----
tempDT = eeMetadata[!is.na(ee.MedianCor)]
histDT = hist(tempDT$ee.MedianCor, breaks = 'FD', plot = FALSE)

tempGG = ggplot(tempDT, aes(x = ee.MedianCor)) +
	geom_histogram(breaks = histDT$breaks) +
	scale_y_continuous(
		trans = 'log10',
		expand = expand_scale(mult = c(0.01, 0.05)),
		labels = function(x) {sprintf('%s', log10(x))}
	) +
	xlab(expression(rho[median])) +
	ylab(expression('log'[10]*' # Datasets'))

# [R1] Sample-Correlation -----
# Mean, Mode, Range, N >= 0.9
reportVal_Mean_Cor = tempDT[, mean(ee.MedianCor, na.rm = TRUE)]
reportVal_Mode_Cor = histDT$mids[which.max(histDT$counts)]
reportVal_Min_Cor = tempDT[, min(ee.MedianCor, na.rm = TRUE)]
reportVal_Max_Cor = tempDT[, max(ee.MedianCor, na.rm = TRUE)]
reportVal_0.9_Cor = tempDT[ee.MedianCor >= 0.9, .N]

# Value Formatting
reportVal_Mean_Cor = sprintf('%.4f', reportVal_Mean_Cor)
reportVal_Mode_Cor = sprintf('%.4f', reportVal_Mode_Cor)
reportVal_Min_Cor = sprintf('%.4f', reportVal_Min_Cor)
reportVal_Max_Cor = sprintf('%.4f', reportVal_Max_Cor)

# [R2] Outlier -----
# Dataset-Count, Range (# Outlier), Range (Ratio), Mean (Ratio)
reportVal_N_Outlier = tempDT[ee.NumOutlier > 0, .N]
reportVal_Min_Outlier = tempDT[ee.NumOutlier > 0, min(ee.NumOutlier)]
reportVal_Max_Outlier = tempDT[ee.NumOutlier > 0, max(ee.NumOutlier)]
reportVal_Min_OutlierRatio = tempDT[ee.NumOutlier > 0, min(ee.NumOutlier/ee.NumSample)]
reportVal_Max_OutlierRatio = tempDT[ee.NumOutlier > 0, max(ee.NumOutlier/ee.NumSample)]
reportVal_Mean_OutlierRatio = tempDT[ee.NumOutlier > 0, mean(ee.NumOutlier/ee.NumSample)]

# Value Formatting
reportVal_Min_OutlierRatio = sprintf('%.4f', reportVal_Min_OutlierRatio)
reportVal_Max_OutlierRatio = sprintf('%.4f', reportVal_Max_OutlierRatio)
reportVal_Mean_OutlierRatio = sprintf('%.4f', reportVal_Mean_OutlierRatio)

# [R3] Batch Information -----
# Has Batch, Original-OK, Corrected, Confounded, Illumina-Microarray (No Batch)
reportVal_N_HasBatch = eeMetadata[(ee.HasBatch), .N]
reportVal_N_BatchOK = eeMetadata[ee.HasBatch & !(ee.IsCorrected | ee.IsConfounded | ee.BatchEffected), .N]
reportVal_N_Corrected = eeMetadata[ee.HasBatch & ee.IsCorrected, .N]

tempDT = eeMetadata[ad.Type == 'ONECOLOR' & ad.Company == 'Illumina']
reportVal_N_Illumina = tempDT[, .N]
reportVal_N_Illumina_NoBatch = tempDT[!(ee.HasBatch), .N]

# [R4] Reprocessed and PMID -----
# Reprocessed (Total, Microarray)
reportVal_N_Reprocessed = eeMetadata[(ee.IsReprocessed), .N]
reportVal_N_Reprocessed_Microarray = eeMetadata[ee.IsReprocessed & ad.Type %in% c('ONECOLOR', 'TWOCOLOR', 'DUALMODE'), .N]
reportVal_N_PMID = eeMetadata[!is.na(ee.PMID), .N]

# Cowplot Output -----
tempPath = sprintf('%sFigure_3.png', outDir)
save_plot(tempPath, plot = tempGG, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('Cor (Mean): %s\n', reportVal_Mean_Cor),
	sprintf('Cor (Mode): %s\n', reportVal_Mode_Cor),
	sprintf('Cor (Range): %s - %s\n', reportVal_Min_Cor, reportVal_Max_Cor),
	sprintf('# Datasets (Cor >= 0.9): %s\n', reportVal_0.9_Cor),
	
	sprintf('# Datasets (Outlier): %s\n', reportVal_N_Outlier),
	sprintf('Outlier (Range): %s - %s\n', reportVal_Min_Outlier, reportVal_Max_Outlier),
	sprintf('Outlier Ratio (Range): %s - %s\n', reportVal_Min_OutlierRatio, reportVal_Max_OutlierRatio),
	sprintf('Outlier Ratio (Mean): %s\n', reportVal_Mean_OutlierRatio),
	
	sprintf('# Datasets (HasBatch): %s\n', reportVal_N_HasBatch),
	sprintf('# Datasets (BatchOK): %s\n', reportVal_N_BatchOK),
	sprintf('# Datasets (BatchCorrected): %s\n', reportVal_N_Corrected),
	sprintf('# Datasets (Illumina-Microarray): %s\n', reportVal_N_Illumina),
	sprintf('# Datasets (Illumina-NoBatch): %s\n', reportVal_N_Illumina_NoBatch),
	
	sprintf('# Datasets (Reprocessed): %s\n', reportVal_N_Reprocessed),
	sprintf('# Datasets (Reprocessed-Microarray): %s\n', reportVal_N_Reprocessed_Microarray),
	sprintf('# Datasets (HasPMID): %s\n', reportVal_N_PMID),
	file = outLogPath,
	sep = '',
	append = TRUE
)