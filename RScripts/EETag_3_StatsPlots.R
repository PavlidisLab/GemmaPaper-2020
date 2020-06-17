# Experiment Tag-Level Plots (3: DO)

# Set Working Directory

# Load Libraries
require(data.table)
require(ggplot2)
require(cowplot)
require(igraph)
require(stringi)
source('DEPENDENCY_Ontology.R')

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
outLogPath = sprintf('%sEETag_3.LOG', outDir)
cat('Output Log:\n', file = outLogPath, sep = '', append = FALSE)

# Custom Function
AddItemToList = function(inputList, inputObject) {
	inputList[[length(inputList) + 1]] = inputObject
	return(inputList)
}

# Main Subroutine -------------------------------------------------------
# Preparation (Metadata)
cat('Loading Metadata.\n')
eeMetadata = fread('EE_Export.TSV', sep = '\t', header = TRUE)
tagMetadata = fread('EETag_Export.TSV', sep = '\t', header = TRUE)

eeMetadata = eeMetadata[!(ee.IsTroubled | ee.IsBlacklisted) & ee.IsPublic]
eeMetadata = eeMetadata[targetTaxon, on = 'ee.Taxon']
tagMetadata = tagMetadata[eeMetadata[, .(ee.ID)], on = 'ee.ID', nomatch = 0]

# Preparation (Ontology)
cat('Loading Ontology.\n')
fullOntDT = fread('Ontology_Dump_MERGED.TSV', sep = '\t', header = TRUE)
fullOntDefDT = fread('Ontology_Dump_MERGED_DEF.TSV', sep = '\t', header = TRUE)

# DO Graph
tempDT = fullOntDT[OntologyScope == 'DO'][grepl('^DOID_', ParentNode)]
doidGraph = graph_from_data_frame(d = unique(tempDT[, .(ChildNode, ParentNode)]))
doidDefDT = unique(fullOntDefDT[OntologyScope == 'DO', .(Node, Definition)])

# ----- Generate Statistics/Plots -----
tempPlotList = list()

# (Propagate DO Terms) -----
# Raw-Counts
tagMetadata_do = tagMetadata[!is.na(et.ValShortURI)][grepl('^DOID_', et.ValShortURI)]
tagMetadata_do = unique(tagMetadata_do[, .(ee.ID, et.ValShortURI)])
tagMetadata_do = tagMetadata_do[et.ValShortURI %in% names(V(doidGraph))]
tagCount_do = tagMetadata_do[, .N, et.ValShortURI]

# [R1] DO-linked EE-Count; DO Term-Count -----
reportVal_N_EE_DO = tagMetadata_do[, uniqueN(ee.ID)]
reportVal_N_TAG_DO_PRE = nrow(tagMetadata_do)

# Post-Propagation
tagMetadata_do = OntPropagateParentNodes(doidGraph, tagMetadata_do)
tagCount_do_exp = tagMetadata_do[, .N, et.ValShortURI]
setorder(tagCount_do_exp, -N)
tagCount_do_exp = doidDefDT[tagCount_do_exp, on = c('Node' = 'et.ValShortURI')]

# [R2] DO Term-Count -----
reportVal_N_TAG_DO_POST = nrow(tagMetadata_do)

# By-Taxon Counts
tempTaxonVector = eeMetadata[tagMetadata_do[, .(ee.ID)], ee.Taxon, on = 'ee.ID']
tagMetadata_do[, ee.Taxon := tempTaxonVector]
tagCount_do_taxon = tagMetadata_do[, .N, .(et.ValShortURI, ee.Taxon)]
setorder(tagCount_do_taxon, -N)
tagCount_do_taxon = doidDefDT[tagCount_do_taxon, on = c('Node' = 'et.ValShortURI')]
rm(tempTaxonVector)

# 1. System-Level/Cancer/Neuronal (By-Taxon) Top-10 -----
doSystemVector = c(
	"DOID_162",
	"DOID_863",
	"DOID_74",
	"DOID_1289",
	"DOID_77",
	"DOID_17",
	"DOID_0060118",
	"DOID_1579",
	"DOID_150",
	"DOID_630"
)

doCancerVector = c(
	"DOID_1612",
	"DOID_1240",
	"DOID_1319",
	"DOID_1324",
	"DOID_184",
	"DOID_0060058",
	"DOID_3571",
	"DOID_10283",
	"DOID_2394",
	"DOID_1793"
)

doNeuronalVector = c(
	"DOID_10652",
	"DOID_14330",
	"DOID_5419",
	"DOID_332",
	"DOID_2377",
	"DOID_12858",
	"DOID_0060041",
	"DOID_1826",
	"DOID_3312",
	"DOID_1470"
)

doNeuronalMapVector = c(
	"Alzheimer's disease" = "Alzheimer's",
	"Parkinson's disease" = "Parkinson's",
	"schizophrenia" = "schizophrenia",
	"amyotrophic lateral sclerosis" = "ALS",
	"multiple sclerosis" = "MS",
	"Huntington's disease" = "Huntington's",
	"autism spectrum disorder" = "ASD",
	"epilepsy" = "epilepsy",
	"bipolar disorder" = "BD",
	"major depressive disorder" = "MDD"
)

# System-Level
tempDT = tagCount_do_taxon[doSystemVector, on = 'Node']
tempDT[, Definition := stri_replace(str = Definition, replacement = '', regex = ' system disease$| disease$|^disease of ')]
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 2000),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Disease (System)') +
	ylab('# Datasets')
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (System-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cancer-Type
tempDT = tagCount_do_taxon[doCancerVector, on = 'Node']
tempDT[, Definition := stri_replace(str = Definition, replacement = '', regex = ' cancer$')]
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 300),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Disease (Cancer)') +
	ylab('# Datasets')
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Cancer) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Neuronal-Type
tempDT = tagCount_do_taxon[doNeuronalVector, on = 'Node']
tempDT[, Definition := doNeuronalMapVector[Definition]]
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 125),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Disease (Neuronal)') +
	ylab('# Datasets')
legendPlotList = get_legend(tempGG)
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Neuronal) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cowplot Output -----
tempCPlot = plot_grid(
	plotlist = tempPlotList,
	nrow = 1,
	ncol = 3,
	labels = LETTERS[1:3]
)
tempCPlot = plot_grid(
	tempCPlot,
	legendPlotList,
	nrow = 1,
	ncol = 2,
	rel_widths = c(3, .3)
)
tempPath = sprintf('%sFigure_7.png', outDir)
save_plot(tempPath, plot = tempCPlot, nrow = 1, ncol = 3.3, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# EE (DO): %s\n', reportVal_N_EE_DO),
	sprintf('# Tags (Pre-Propagate): %s\n', reportVal_N_TAG_DO_PRE),
	sprintf('# Tags (Post-Propagate): %s\n', reportVal_N_TAG_DO_POST),
	file = outLogPath,
	sep = '',
	append = TRUE
)