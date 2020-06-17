# Experiment Tag-Level Plots (2: UBERON + CL)

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
outLogPath = sprintf('%sEETag_2.LOG', outDir)
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

# UBERON + CL Graph
tempDT = fullOntDT[c('UBERON', 'CL'), on = 'OntologyScope'][grepl('^UBERON_|^CL_', ParentNode)]
uberonclGraph = graph_from_data_frame(d = unique(tempDT[, .(ChildNode, ParentNode)]))
uberonclDefDT = unique(fullOntDefDT[c('UBERON', 'CL'), .(Node, Definition), on = 'OntologyScope'])

# ----- Generate Statistics/Plots -----
tempPlotList_A = list()
tempPlotList_B = list()

# [R1] EE-Count -----
reportVal_N_EE = nrow(eeMetadata)

# (Propagate UBERON_CL Terms) -----
# Raw-Counts
tagMetadata_uberoncl = tagMetadata[!is.na(et.ValShortURI)][grepl('^UBERON_|^CL_', et.ValShortURI)]
tagMetadata_uberoncl = unique(tagMetadata_uberoncl[, .(ee.ID, et.ValShortURI)])
tagMetadata_uberoncl = tagMetadata_uberoncl[et.ValShortURI %in% names(V(uberonclGraph))]
tagCount_uberoncl = tagMetadata_uberoncl[, .N, et.ValShortURI]

# [R2] UBERON/CL-linked EE-Count; UBERON/CL Term-Count -----
reportVal_N_EE_UC = tagMetadata_uberoncl[, uniqueN(ee.ID)]
reportVal_N_TAG_UC_PRE = nrow(tagMetadata_uberoncl)

# Post-Propagation
tagMetadata_uberoncl = OntPropagateParentNodes(uberonclGraph, tagMetadata_uberoncl)
tagCount_uberoncl_exp = tagMetadata_uberoncl[, .N, et.ValShortURI]

# [R3] UBERON/CL Term-Count -----
reportVal_N_TAG_UC_POST = nrow(tagMetadata_uberoncl)

# Merge Pre/Post-Propagation Term Counts
mergedCount_uberoncl = merge(x = tagCount_uberoncl, y = tagCount_uberoncl_exp, by = 'et.ValShortURI', all = TRUE)
colnames(mergedCount_uberoncl)[2:3] = c('PrePropagate.N', 'PostPropagate.N')
setorder(mergedCount_uberoncl, -PostPropagate.N)
mergedCount_uberoncl[is.na(PrePropagate.N), PrePropagate.N := 0]
mergedCount_uberoncl = uberonclDefDT[mergedCount_uberoncl, on = c('Node' = 'et.ValShortURI')]
rm(tagCount_uberoncl_exp)

# By-Taxon Counts
tempTaxonVector = eeMetadata[tagMetadata_uberoncl[, .(ee.ID)], ee.Taxon, on = 'ee.ID']
tagMetadata_uberoncl[, ee.Taxon := tempTaxonVector]
tagCount_uberoncl_taxon = tagMetadata_uberoncl[, .N, .(et.ValShortURI, ee.Taxon)]
setorder(tagCount_uberoncl_taxon, -N)
tagCount_uberoncl_taxon = uberonclDefDT[tagCount_uberoncl_taxon, on = c('Node' = 'et.ValShortURI')]
rm(tempTaxonVector)

# [R4] Child-Term Count -----
reportVal_N_CHILD_MICROGLIAL = length(OntGetChildNodes(uberonclGraph, 'CL_0000129')) - 1
reportVal_N_CHILD_BRAIN = length(OntGetChildNodes(uberonclGraph, 'UBERON_0000955')) - 1

# 1. System-/Tissue-/Cell-Level (By-Taxon) Top-10 -----
uberonSystemVector = c(
	"UBERON_0001016",
	"UBERON_0002193",
	"UBERON_0001007",
	"UBERON_0002204",
	"UBERON_0000949",
	"UBERON_0002330",
	"UBERON_0002423",
	"UBERON_0001004",
	"UBERON_0004535",
	"UBERON_0000990"
)

uberonTissueVector = c(
	"UBERON_0000955",
	"UBERON_0000178",
	"UBERON_0002107",
	"UBERON_0002048",
	"UBERON_0005090",
	"UBERON_0000160",
	"UBERON_0000948",
	"UBERON_0002106",
	"UBERON_0002113",
	"UBERON_0002240"
)

uberonCellVector = c(
	"CL_0000988",
	"CL_0000738",
	"CL_0000066",
	"CL_0000125",
	"CL_0000057",
	"CL_0000235",
	"CL_0000084",
	"CL_0002322",
	"CL_0000236",
	"CL_0000129"
)

# System-Level
tempDT = tagCount_uberoncl_taxon[uberonSystemVector, on = 'Node']
tempDT[, Definition := stri_replace(str = Definition, replacement = '', regex = ' system$')]
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 4000),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('System') +
	ylab('# Datasets')
tempPlotList_A = AddItemToList(tempPlotList_A, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (System-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Organ-Level
tempDT = tagCount_uberoncl_taxon[uberonTissueVector, on = 'Node']
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 2500),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Organ/Tissue') +
	ylab('# Datasets')
tempPlotList_A = AddItemToList(tempPlotList_A, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Organ-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cell-Level
tempDT = tagCount_uberoncl_taxon[uberonCellVector, on = 'Node']
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 1500),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Cell Type') +
	ylab('# Datasets')
legendPlotList_A = get_legend(tempGG)
tempPlotList_A = AddItemToList(tempPlotList_A, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Cell-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# 2. Pre/Post-Propagation Top-10 -----
# Organ-Level
tempDT = melt.data.table(
	mergedCount_uberoncl[uberonTissueVector, on = 'Node'],
	id.vars = c('Node', 'Definition'),
	measure.vars = c('PrePropagate.N', 'PostPropagate.N'),
	variable.name = 'Inference',
	value.name = 'N'
)
levels(tempDT$Inference) = list(
	'Before' = 'PrePropagate.N',
	'After' = 'PostPropagate.N'
)
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, max), y = N, group = Inference, fill = Inference)) +
	geom_col(position = 'dodge') +
	scale_y_continuous(
		limits = c(0, 2500),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	coord_flip() +
	xlab('Organ/Tissue') +
	ylab('# Datasets')
tempPlotList_B = AddItemToList(tempPlotList_B, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Pre/Post + Organ-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
tempDT = mergedCount_uberoncl[uberonTissueVector, on = 'Node']
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cell-Level
tempDT = melt.data.table(
	mergedCount_uberoncl[uberonCellVector, on = 'Node'],
	id.vars = c('Node', 'Definition'),
	measure.vars = c('PrePropagate.N', 'PostPropagate.N'),
	variable.name = 'Inference',
	value.name = 'N'
)
levels(tempDT$Inference) = list(
	'Before' = 'PrePropagate.N',
	'After' = 'PostPropagate.N'
)
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, max), y = N, group = Inference, fill = Inference)) +
	geom_col(position = 'dodge') +
	scale_y_continuous(
		limits = c(0, 1500),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_discrete(
		guide = guide_legend(title = 'Inference')
	) +
	coord_flip() +
	xlab('Cell Type') +
	ylab('# Datasets')
legendPlotList_B = get_legend(tempGG)
tempPlotList_B = AddItemToList(tempPlotList_B, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Pre/Post + Cell-Level) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
tempDT = mergedCount_uberoncl[uberonCellVector, on = 'Node']
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cowplot Output -----
tempCPlot_A = plot_grid(
	plotlist = tempPlotList_A,
	nrow = 1,
	ncol = 3,
	labels = LETTERS[1:3]
)
tempCPlot_A = plot_grid(
	tempCPlot_A,
	legendPlotList_A,
	nrow = 1,
	ncol = 2,
	rel_widths = c(3, .3)
)

tempCPlot_B = plot_grid(
	plotlist = tempPlotList_B,
	nrow = 1,
	ncol = 2,
	labels = LETTERS[1:2]
)
tempCPlot_B = plot_grid(
	tempCPlot_B,
	legendPlotList_B,
	nrow = 1,
	ncol = 2,
	rel_widths = c(2, .3)
)

tempPath = sprintf('%sFigure_5.png', outDir)
save_plot(tempPath, plot = tempCPlot_A, nrow = 1, ncol = 3.3, type = 'cairo')
tempPath = sprintf('%sFigure_6.png', outDir)
save_plot(tempPath, plot = tempCPlot_B, nrow = 1, ncol = 2.3, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# EE: %s\n', reportVal_N_EE),
	sprintf('# EE (UBERON/CL): %s\n', reportVal_N_EE_UC),
	sprintf('# Tags (Pre-Propagate): %s\n', reportVal_N_TAG_UC_PRE),
	sprintf('# Tags (Post-Propagate): %s\n', reportVal_N_TAG_UC_POST),
	sprintf('# Child (Microglial Cell): %s\n', reportVal_N_CHILD_MICROGLIAL),
	sprintf('# Child (Brain): %s\n', reportVal_N_CHILD_BRAIN),
	file = outLogPath,
	sep = '',
	append = TRUE
)