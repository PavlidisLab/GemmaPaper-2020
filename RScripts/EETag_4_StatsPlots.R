# Experiment Tag-Level Plots (4: CHEBI)

# Set Working Directory

# Load Libraries
require(data.table)
require(ggplot2)
require(cowplot)
require(igraph)
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
outLogPath = sprintf('%sEETag_4.LOG', outDir)
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

# CHEBI Full-Graph
tempDT = fullOntDT[OntologyScope == 'CHEBI'][grepl('^CHEBI_', ParentNode)]
chebiFullGraph = graph_from_data_frame(d = unique(tempDT[, .(ChildNode, ParentNode)]))

# CHEBI Graph (Type: is_a)
tempDT = fullOntDT[OntologyScope == 'CHEBI' & RelationType == 'is_a'][grepl('^CHEBI_', ParentNode)]
chebiISAGraph = graph_from_data_frame(d = unique(tempDT[, .(ChildNode, ParentNode)]))

# CHEBI Graph (Type: has_role)
tempDT = fullOntDT[OntologyScope == 'CHEBI' & RelationType == 'has_role'][grepl('^CHEBI_', ParentNode)]
chebiRoleGraph = graph_from_data_frame(d = unique(tempDT[, .(ChildNode, ParentNode)]))
chebiDefDT = unique(fullOntDefDT[OntologyScope == 'CHEBI', .(Node, Definition)])

# Role-Specific Children Terms
roleChildVector = unique(c(
	OntGetChildNodes(chebiISAGraph, 'CHEBI_24432'),
	OntGetChildNodes(chebiISAGraph, 'CHEBI_33232')
))

# ----- Generate Statistics/Plots -----
tempPlotList = list()

# (Propagate CHEBI Terms) -----
tagMetadata_chebi = tagMetadata[!is.na(et.ValShortURI)][grepl('^CHEBI_', et.ValShortURI)]
tagMetadata_chebi = unique(tagMetadata_chebi[, .(ee.ID, et.ValShortURI)])
tagMetadata_chebi = tagMetadata_chebi[et.ValShortURI %in% names(V(chebiFullGraph))]
tagCount_chebi = tagMetadata_chebi[, .N, et.ValShortURI]
setorder(tagCount_chebi, -N)
tagCount_chebi = chebiDefDT[tagCount_chebi, on = c('Node' = 'et.ValShortURI')]

# [R1] CHEBI-linked EE-Count; CHEBI Term-Count -----
reportVal_N_EE_CHEBI = tagMetadata_chebi[, uniqueN(ee.ID)]
reportVal_N_TAG_CHEBI_PRE = nrow(tagMetadata_chebi)

# Post-Propagation (Type: has_role)
tagMetadata_chebi_role = tagMetadata_chebi[et.ValShortURI %in% names(V(chebiRoleGraph))]
tagMetadata_chebi_role = OntPropagateParentNodes(chebiRoleGraph, tagMetadata_chebi_role)
tagCount_chebi_exp = tagMetadata_chebi_role[, .N, et.ValShortURI]
tagCount_chebi_exp = tagCount_chebi_exp[roleChildVector, on = 'et.ValShortURI', nomatch = 0]
setorder(tagCount_chebi_exp, -N)
tagCount_chebi_exp = chebiDefDT[tagCount_chebi_exp, on = c('Node' = 'et.ValShortURI')]

# [R2] CHEBI Term-Count -----
reportVal_N_TAG_CHEBI_POST = nrow(tagMetadata_chebi_role)

# By-Taxon Counts
# (Pre-Propagation)
tempTaxonVector = eeMetadata[tagMetadata_chebi[, .(ee.ID)], ee.Taxon, on = 'ee.ID']
tagMetadata_chebi[, ee.Taxon := tempTaxonVector]
tagCount_chebi_taxon = tagMetadata_chebi[, .N, .(et.ValShortURI, ee.Taxon)]
setorder(tagCount_chebi_taxon, -N)
tagCount_chebi_taxon = chebiDefDT[tagCount_chebi_taxon, on = c('Node' = 'et.ValShortURI')]
rm(tempTaxonVector)

# (Post-Propagation)
tempTaxonVector = eeMetadata[tagMetadata_chebi_role[, .(ee.ID)], ee.Taxon, on = 'ee.ID']
tagMetadata_chebi_role[, ee.Taxon := tempTaxonVector]
tagCount_chebi_exp_taxon = tagMetadata_chebi_role[, .N, .(et.ValShortURI, ee.Taxon)]
tagCount_chebi_exp_taxon = tagCount_chebi_exp_taxon[roleChildVector, on = 'et.ValShortURI', nomatch = 0]
setorder(tagCount_chebi_exp_taxon, -N)
tagCount_chebi_exp_taxon = chebiDefDT[tagCount_chebi_exp_taxon, on = c('Node' = 'et.ValShortURI')]
rm(tempTaxonVector)

# 1. Raw Counts/Role (By-Taxon) Top-10 -----
chebiRoleVector = c(
	"CHEBI_35610",
	"CHEBI_50910",
	"CHEBI_35705",
	"CHEBI_33281",
	"CHEBI_24621",
	"CHEBI_50905",
	"CHEBI_68495",
	"CHEBI_64018",
	"CHEBI_60643",
	"CHEBI_50919"
)

chebiRoleMapVector = c(
	"antineoplastic agent" = "antineoplastic",
	"neurotoxin" = "neurotoxin",
	"immunosuppressive agent" = "immunosuppressive",
	"antimicrobial agent" = "antimicrobial",
	"hormone" = "hormone",
	"teratogenic agent" = "teratogenic",
	"apoptosis inducer" = "apoptosis inducer",
	"protein kinase C agonist" = "PKC agonist",
	"NMDA receptor antagonist" = "NMDAR antagonist",
	"antiemetic" = "antiemetic"
)

# Raw Counts
tempDT = tagCount_chebi_taxon[tagCount_chebi[1:10, .(Node)], on = 'Node']
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 200),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Compounds') +
	ylab('# Datasets')
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Raw Counts) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Role: Biological Role + Application
tempDT = tagCount_chebi_exp_taxon[chebiRoleVector, on = 'Node']
tempDT[, Definition := chebiRoleMapVector[Definition]]
tempGG = ggplot(tempDT, aes(x = reorder(Definition, N, sum), y = N, group = ee.Taxon, fill = ee.Taxon)) +
	geom_col() +
	scale_y_continuous(
		limits = c(0, 600),
		expand = expand_scale(mult = c(0.01, 0.05))
	) +
	scale_fill_manual(
		values = colorMap,
		guide = guide_legend(title = 'Taxon')
	) +
	coord_flip() +
	xlab('Role') +
	ylab('# Datasets')
legendPlotList = get_legend(tempGG)
tempPlotList = AddItemToList(tempPlotList, tempGG + theme(legend.position = 'none'))

cat(
	'\n\n----- # EE By Taxon (Role) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(tempDT, file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R3] CHEBI Children Term-Count (antineoplastic agent) -----
top10Terms = tagCount_chebi[1:10, Node]
targetEE = unique(tagMetadata_chebi_role[et.ValShortURI == 'CHEBI_35610', ee.ID])
targetChildTerms = OntGetChildNodes(chebiRoleGraph, 'CHEBI_35610')
targetTable = tagMetadata_chebi[.(targetEE), on = 'ee.ID'][.(targetChildTerms), on = 'et.ValShortURI', nomatch = 0]
targetCounts = targetTable[, .N, et.ValShortURI][order(-N)]
finalTable = chebiDefDT[targetCounts, on = c('Node' = 'et.ValShortURI')]

reportVal_N_CHEBI_ANTINEOPLASTIC = finalTable[, .N]

cat(
	'\n\n----- # EE By Taxon (Antineoplastic) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(finalTable[.(top10Terms), on = 'Node', nomatch = 0], file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R4] CHEBI Children Term-Count (neurotoxin) -----
top10Terms = tagCount_chebi[1:10, Node]
targetEE = unique(tagMetadata_chebi_role[et.ValShortURI == 'CHEBI_50910', ee.ID])
targetChildTerms = OntGetChildNodes(chebiRoleGraph, 'CHEBI_50910')
targetTable = tagMetadata_chebi[.(targetEE), on = 'ee.ID'][.(targetChildTerms), on = 'et.ValShortURI', nomatch = 0]
targetCounts = targetTable[, .N, et.ValShortURI][order(-N)]
finalTable = chebiDefDT[targetCounts, on = c('Node' = 'et.ValShortURI')]

reportVal_N_CHEBI_NEUROTOXIN = finalTable[, .N]

cat(
	'\n\n----- # EE By Taxon (Neurotoxin) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(finalTable[.(top10Terms), on = 'Node', nomatch = 0], file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R5] CHEBI Children Term-Count (immunosuppressive agent) -----
top10Terms = tagCount_chebi[1:10, Node]
targetEE = unique(tagMetadata_chebi_role[et.ValShortURI == 'CHEBI_35705', ee.ID])
targetChildTerms = OntGetChildNodes(chebiRoleGraph, 'CHEBI_35705')
targetTable = tagMetadata_chebi[.(targetEE), on = 'ee.ID'][.(targetChildTerms), on = 'et.ValShortURI', nomatch = 0]
targetCounts = targetTable[, .N, et.ValShortURI][order(-N)]
finalTable = chebiDefDT[targetCounts, on = c('Node' = 'et.ValShortURI')]

reportVal_N_CHEBI_IMMUNOSUPPRESSIVE = finalTable[, .N]

cat(
	'\n\n----- # EE By Taxon (Immunosuppressive) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(finalTable[.(top10Terms), on = 'Node', nomatch = 0], file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# [R6] CHEBI Term-Count (doxorubicin) -----
reportVal_N_CHEBI_DOXORUBICIN = tagCount_chebi[Node == 'CHEBI_28748', N]

cat(
	'\n\n----- # EE By Taxon (Immunosuppressive) -----\n',
	file = outLogPath,
	sep = '',
	append = TRUE
)
write.table(finalTable[.(top10Terms), on = 'Node', nomatch = 0], file = outLogPath, append = TRUE, quote = FALSE, row.names = FALSE, sep = '\t')

# Cowplot Output -----
tempCPlot = plot_grid(
	plotlist = tempPlotList,
	nrow = 1,
	ncol = 2,
	labels = LETTERS[1:2]
)
tempCPlot = plot_grid(
	tempCPlot,
	legendPlotList,
	nrow = 1,
	ncol = 2,
	rel_widths = c(2, .3)
)
tempPath = sprintf('%sFigure_8.png', outDir)
save_plot(tempPath, plot = tempCPlot, nrow = 1, ncol = 2.3, type = 'cairo')

# Statistics Reporting -----
cat(
	'\n\n',
	sprintf('# EE (CHEBI): %s\n', reportVal_N_EE_CHEBI),
	sprintf('# Tags (Pre-Propagate): %s\n', reportVal_N_TAG_CHEBI_PRE),
	sprintf('# Tags (Post-Propagate): %s\n', reportVal_N_TAG_CHEBI_POST),
	
	sprintf('# Used Child Terms (Antineoplastic): %s\n', reportVal_N_CHEBI_ANTINEOPLASTIC),
	sprintf('# Used Child Terms (Neurotoxin): %s\n', reportVal_N_CHEBI_NEUROTOXIN),
	sprintf('# Used Child Terms (Immunosuppressive): %s\n', reportVal_N_CHEBI_IMMUNOSUPPRESSIVE),
	
	sprintf('# EE (Doxorubicin): %s\n', reportVal_N_CHEBI_DOXORUBICIN),
	file = outLogPath,
	sep = '',
	append = TRUE
)