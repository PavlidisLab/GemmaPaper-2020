# Experiment-Level Plots (1: General Statistics)

# Set Working Directory

# Load Libraries
require(data.table)
require(ggplot2)
require(cowplot)

# Declaring Global Variables
outDir = 'ROutput/'
targetTaxon = c('human', 'mouse', 'rat')

# NOTE: HUE_PAL, Human = Red, Mouse = Green, Rat = Blue
colorMap = c(
	'human' = '#F8766D',
	'mouse' = '#00BA38',
	'rat' = '#619CFF'
)

options(
	stringsAsFactors = FALSE,
	warn = 1
)

# Global Preparation ------------------------------------------------------
# Creation of Output Directory
dir.create(outDir, recursive = TRUE, showWarnings = FALSE)

# Creation of Output Log
outLogPath = sprintf('%sEE_1.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Custom Function
AddItemToList = function(inputList, inputObject) {
	inputList[[length(inputList) + 1]] = inputObject
	return(inputList)
}

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
blMetadata = fread('BL_Export.TSV', sep = '\t', header = TRUE)

# ----- Generate Statistics/Plots -----
tempPlotList = list()

# (Pre-Public Filter) -----
# [R1] EE-Count (Troubled + Blacklist) -----
reportVal_N_EE_BT = blMetadata[geo.Type == 'Experiment', .N] + eeMetadata[(ee.IsTroubled & !(ee.IsBlacklisted)), .N]
rm(blMetadata)

# (Post-Public Filter/Pre-Taxon Filter) -----
eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted | is.na(ee.Taxon)) & ee.IsPublic]
eeMetadata[, ee.SimpleTaxon := ifelse(ee.Taxon %in% targetTaxon, ee.Taxon, 'others')]

# [R2] Post-Filter EE and Sample Count -----
reportVal_N_EE_Filter = nrow(eeMetadata)
reportVal_N_Sample_Filter = eeMetadata[, sum(ee.NumSample)]

# 1. EE-Count By Taxon -----
tempDT = eeMetadata[, .N, ee.SimpleTaxon]
setorder(tempDT, -N)

tempGG = ggplot(tempDT, aes(x = reorder(ee.SimpleTaxon, N), y = N)) +
	geom_col() +
	scale_y_continuous(
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	coord_flip() +
	xlab('Taxon') +
	ylab('# Datasets')
tempPlotList = AddItemToList(tempPlotList, tempGG)

# [TABLE-1] (HMR) EE-Count -----
tempDT = eeMetadata[, .N, ee.Taxon]
setorder(tempDT, -N)

cat(
	'\n\n----- # EE By Taxon -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# 2. Sample-Count By Taxon -----
tempDT = eeMetadata[, .(N = sum(ee.NumSample)), ee.SimpleTaxon]
setorder(tempDT, -N)

tempGG = ggplot(tempDT, aes(x = reorder(ee.SimpleTaxon, N), y = N/1000)) +
	geom_col() +
	scale_y_continuous(
		expand = expand_scale(mult = c(0.01, 0.05)),
		labels = function(x) {sprintf('%s K', x)},
		limits = c(0, 250)
	) +
	coord_flip() +
	xlab('Taxon') +
	ylab('# Samples')
tempPlotList = AddItemToList(tempPlotList, tempGG)

# [TABLE-2] (HMR) Sample-Count -----
tempDT = eeMetadata[, .(N = sum(ee.NumSample)), ee.Taxon]
setorder(tempDT, -N)

cat(
	'\n\n----- # Sample By Taxon -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# (Post-Taxon Filter) -----
eeMetadata = eeMetadata[targetTaxon, , on = 'ee.Taxon']

# 3. ECDF (# Sample per Dataset By Taxon) -----
tempGG = ggplot(eeMetadata, aes(x = log10(ee.NumSample), group = ee.Taxon, colour = ee.Taxon)) +
	geom_step(stat = 'ecdf') +
	xlab(expression('log'[10]*' # Samples per Dataset')) +
	ylab('ECDF') +
	scale_colour_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	)
legendPlotList = get_legend(tempGG)
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))
tempPlotList = AddItemToList(tempPlotList, legendPlotList)

# [R3] EE and Sample-Count By Technology -----
tempDT = eeMetadata[, .(ee.ID, ee.NumSample, ad.Type)]
tempDT[ad.Type == 'GENELIST', ad.Type := 'SEQUENCING']

reportVal_N_EE_Microarray = tempDT[ad.Type != 'SEQUENCING', .N]
reportVal_N_Sample_Microarray = tempDT[ad.Type != 'SEQUENCING', sum(ee.NumSample)]

# [R4] EE-Count By Source (+ Unique GSE) -----
reportVal_N_EE_GEO = eeMetadata[ee.Source == 'GEO', .N]
reportVal_N_UniqueGSE = eeMetadata[!is.na(ee.OriginalID), uniqueN(ee.OriginalID)]

# [R5] Sample-Count per Dataset -----
# Range, Mean: for Top-90% EE (by Sample-Count)
# EE-Count when Sample-Count >= 100
tempDT = eeMetadata[, .(ee.ID, ee.NumSample)]
setorder(tempDT, ee.NumSample)
tempDT = tempDT[floor(0.1 * nrow(tempDT)):nrow(tempDT)]

reportVal_N_EE_Top90 = tempDT[, .N]
reportVal_N_Sample_Min = tempDT[, min(ee.NumSample)]
reportVal_N_Sample_Max = tempDT[, max(ee.NumSample)]
reportVal_N_Sample_Mean = tempDT[, mean(ee.NumSample)]

reportVal_N_EE_Sample100 = eeMetadata[ee.NumSample >= 100, .N]

# Value Formatting
reportVal_N_Sample_Mean = sprintf('%.4f', reportVal_N_Sample_Mean)

# Cowplot Output -----
tempCPlot = plot_grid(
	plotlist = tempPlotList,
	nrow = 2,
	ncol = 2,
	labels = LETTERS[1:3]
)
tempPath = sprintf('%sFigure_2.png', outDir)
save_plot(tempPath, plot = tempCPlot, nrow = 2, ncol = 2, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# EE (Trouble/Blacklist): %s\n', reportVal_N_EE_BT),
	sprintf('# EE (Public): %s\n', reportVal_N_EE_Filter),
	sprintf('# Sample (Public): %s\n', reportVal_N_Sample_Filter),
	
	sprintf('# EE (Microarray): %s\n', reportVal_N_EE_Microarray),
	sprintf('# Sample (Microarray): %s\n', reportVal_N_Sample_Microarray),
	sprintf('# EE (GEO): %s\n', reportVal_N_EE_GEO),
	sprintf('# Unique GSE: %s\n', reportVal_N_UniqueGSE),
	
	sprintf('# EE (Top-90%% EE by Sample Count): %s\n', reportVal_N_EE_Top90),
	sprintf('# Sample/Dataset (Range): %s - %s\n', reportVal_N_Sample_Min, reportVal_N_Sample_Max),
	sprintf('# Sample/Dataset (Mean): %s\n', reportVal_N_Sample_Mean),
	sprintf('# EE (# Sample >= 100): %s\n', reportVal_N_EE_Sample100),
	file = outLogPath,
	sep = '',
	append = TRUE
)