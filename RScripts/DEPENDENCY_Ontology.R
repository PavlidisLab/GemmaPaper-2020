# Custom Functions

# Load Libraries
require(igraph)
require(data.table)

# 1. Propagate Graph
OntPropagateParentNodes = function(graph, tagDT) {
	require(igraph)
	require(parallel)
	stopifnot(is.igraph(graph))
	stopifnot(is.data.table(tagDT))
	
	tempList = mclapply(X = 1:nrow(tagDT), mc.silent = TRUE, mc.cores = 4, FUN = function(i) {
		parentNodes = OntGetParentNodes(graph = graph, query = tagDT[i, et.ValShortURI])
		return(data.table(ee.ID = tagDT[i, ee.ID], et.ValShortURI = parentNodes))
	})
	finalDT = unique(do.call('rbind', tempList))
	return(finalDT)
}

# 2. Get Parent Terms
OntGetParentNodes = function(graph, query) {
	require(igraph)
	stopifnot(is.igraph(graph))
	stopifnot(is.character(query))
	
	nodes = names(subcomponent(graph = graph, v = query, mode = 'out'))
	return(nodes)
}

# 3. Get Child Terms
OntGetChildNodes = function(graph, query) {
	require(igraph)
	stopifnot(is.igraph(graph))
	stopifnot(is.character(query))
	
	nodes = names(subcomponent(graph = graph, v = query, mode = 'in'))
	return(nodes)
}