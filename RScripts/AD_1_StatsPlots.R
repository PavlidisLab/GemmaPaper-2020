# Platform-Level Plots

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
outLogPath = sprintf('%sAD_1.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Custom Function
AddItemToList = function(inputList, inputObject) {
	inputList[[length(inputList) + 1]] = inputObject
	return(inputList)
}

# Main Subroutine -------------------------------------------------------
# Preparation
cat('Loading Metadata.\n')
adMetadata = fread('AD_Export.TSV', sep = '\t', header = TRUE)
blMetadata = fread('BL_Export.TSV', sep = '\t', header = TRUE)

# ----- Generate Statistics/Plots -----
tempPlotList = list()

# (Pre-Troubled Filter) -----
adMetadata = adMetadata[!(ad.IsBlacklisted | is.na(ad.Taxon))]

# [R1] AD-Count (All, Troubled + Blacklist) -----
reportVal_N_AD_Original = adMetadata[, .N] + blMetadata[geo.Type == 'Platform', .N]
reportVal_N_AD_BT = adMetadata[(ad.IsTroubled), .N] + blMetadata[geo.Type == 'Platform', .N]
rm(blMetadata)

# (Post-Troubled Filter; Pre-Zero Filter) -----
adMetadata = adMetadata[!(ad.IsTroubled)]

# [R2] AD-Count (Alt-Affy, Sequencing-Type) -----
reportVal_N_AD_AltAffy = adMetadata[(ad.IsAltAffy), .N]
reportVal_N_AD_SEQUENCING = adMetadata[ad.TechType == 'SEQUENCING', .N]

# (Post-Zero Filter) -----
adMetadata = adMetadata[!(ad.IsAltAffy | ad.NumEE == 0 | ad.NumProbe == 0 | ad.NumGene == 0)]

# (Sequencing Naming-Harmonization) -----
ncbiSeqMetadata = adMetadata[grepl('^Generic_[a-z]+_ncbiIds$', ad.Name)]
ncbiSeqMetadata[, ad.Name := sprintf('%s RNA-Seq', ad.Taxon)]
allSeqMetadata = adMetadata[c('GENELIST', 'SEQUENCING'), on = 'ad.TechType']
allSeqMetadata = allSeqMetadata[, .(N = sum(ad.NumEE)), ad.Taxon]
ncbiSeqMetadata[allSeqMetadata, ad.NumEE := N, on = 'ad.Taxon']

adMetadata = adMetadata[!(ad.TechType %in% c('GENELIST', 'SEQUENCING'))]
adMetadata = rbind(adMetadata, ncbiSeqMetadata)
rm(ncbiSeqMetadata, allSeqMetadata)

# [R3] AD-Count (OK, Merged) -----
reportVal_N_AD_OK = adMetadata[, .N]
reportVal_N_AD_Merged = adMetadata[(ad.IsMerged), .N]

# (Post-Taxon Filter) -----
adMetadata = adMetadata[targetTaxon, on = 'ad.Taxon']

# [TABLE-1] (HMR) AD-Count -----
tempDT = adMetadata[, .N, ad.Taxon]
setorder(tempDT, -N)

cat(
	'\n\n----- # AD By Taxon -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# 1. AD-Count by EE-Count -----
tempGG = ggplot(adMetadata, aes(x = log10(ad.NumEE))) +
	geom_freqpoly(bins = 20) +
	xlab(expression('log'[10]*' # Datasets per Platform')) +
	ylab('# Platforms')
tempPlotList = AddItemToList(tempPlotList, tempGG)

# 2. Microarray Protein-Gene Ratio vs EE-Count -----
tempDT = adMetadata[ad.TechType != 'GENELIST']
tempGG = ggplot(tempDT, aes(x = log10(ad.NumEE), y = ad.RatioProtGene)) +
	geom_point(alpha = 0.4) +
	xlab(expression('log'[10]*' # Datasets per Platform')) +
	ylab('Protein Gene Fraction')
tempPlotList = AddItemToList(tempPlotList, tempGG)

# [R4] Protein-Gene Ratio (Mean, Range): where EE-Count >= 100 -----
reportVal_PGR_Mean = tempDT[ad.NumEE >= 100, mean(ad.RatioProtGene, na.rm = TRUE)]
reportVal_PGR_Min = tempDT[ad.NumEE >= 100, min(ad.RatioProtGene, na.rm = TRUE)]
reportVal_PGR_Max = tempDT[ad.NumEE >= 100, max(ad.RatioProtGene, na.rm = TRUE)]

# Value Formatting
reportVal_PGR_Mean = sprintf('%.4f', reportVal_PGR_Mean)
reportVal_PGR_Min = sprintf('%.4f', reportVal_PGR_Min)
reportVal_PGR_Max = sprintf('%.4f', reportVal_PGR_Max)

# 3. EE-Count by AD (Top-10) -----
tempDT = adMetadata[, .(ad.Name, ad.Title, ad.Taxon, ad.NumEE)]
setorder(tempDT, -ad.NumEE)
tempDT = tempDT[1:10]

tempGG = ggplot(tempDT, aes(x = reorder(ad.Name, ad.NumEE), y = ad.NumEE, fill = ad.Taxon)) +
	geom_col() +
	coord_flip() +
	xlab('Platform') +
	ylab("# Datasets") +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	scale_y_continuous(
		expand = expand_scale(mult = c(0.01, 0.05)),
		limits = c(0, 1500)
	)
legendPlotList = get_legend(tempGG)
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))
tempPlotList = AddItemToList(tempPlotList, legendPlotList)

# [TABLE-2] (HMR) EE-Count Top-10 AD -----
cat(
	'\n\n----- Top-10 AD By # EE -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R5] AD-Count where (EE-Count = 1, <= 10, >= 100) -----
# Also, EE-Count Sum (All, Microarray) where EE-Count >= 100
reportVal_N_AD_EE_1 = adMetadata[ad.NumEE == 1, .N]
reportVal_N_AD_EE_10 = adMetadata[ad.NumEE <= 10, .N]
reportVal_N_AD_EE_100 = adMetadata[ad.NumEE >= 100, .N]
reportVal_N_AD_EESum_100 = adMetadata[ad.NumEE >= 100, sum(ad.NumEE)]
reportVal_N_AD_EESum_100_Microarray = adMetadata[ad.NumEE >= 100 & ad.TechType != 'GENELIST', sum(ad.NumEE)]

# Cowplot Output -----
tempCPlot = plot_grid(
	plotlist = tempPlotList,
	nrow = 2,
	ncol = 2,
	labels = LETTERS[1:3]
)
tempPath = sprintf('%sFigure_4.png', outDir)
save_plot(tempPath, plot = tempCPlot, nrow = 2, ncol = 2, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# AD (All): %s\n', reportVal_N_AD_Original),
	sprintf('# AD (Trouble/Blacklist): %s\n', reportVal_N_AD_BT),
	
	sprintf('# AD (Alt-Affy): %s\n', reportVal_N_AD_AltAffy),
	sprintf('# AD (Type-Sequencing): %s\n', reportVal_N_AD_SEQUENCING),
	
	sprintf('# AD (OK): %s\n', reportVal_N_AD_OK),
	sprintf('# AD (Merged): %s\n', reportVal_N_AD_Merged),
	
	sprintf('PCG-Ratio, AD where # EE >= 100 (Mean): %s\n', reportVal_PGR_Mean),
	sprintf('PCG-Ratio, AD where # EE >= 100 (Range): %s - %s\n', reportVal_PGR_Min, reportVal_PGR_Max),
	
	sprintf('# AD (# EE = 1): %s\n', reportVal_N_AD_EE_1),
	sprintf('# AD (# EE <= 10): %s\n', reportVal_N_AD_EE_10),
	sprintf('# AD (# EE >= 100): %s\n', reportVal_N_AD_EE_100),
	sprintf('Sum-EE-Count (AD with # EE >= 100): %s\n', reportVal_N_AD_EESum_100),
	sprintf('Sum-EE-Count (AD with # EE >= 100; Microarray): %s\n', reportVal_N_AD_EESum_100_Microarray),
	file = outLogPath,
	sep = '',
	append = TRUE
)