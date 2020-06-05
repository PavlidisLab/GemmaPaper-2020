# Module for Ontology Utilies

# Python Imports
from collections import Iterable
from PyVersion import PyCheckLenient
from StrUtils import FormatASCII

# Java Imports
from ubic.basecode.ontology.model import OntologyTerm
from ubic.gemma.model.common.description import AnnotationValueObject
from ubic.gemma.model.common.description import Characteristic

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


class BasicOntTerm(object):
	# Class structure of the fundamental ontology term

	def __init__(self):
		# Initialize
		self.termValue = 'NA'
		self.termURI = 'NA'
		self.shortURI = 'NA'

	def importValues(self, inputValue, inputURI):
		# Populate ontology term
		assert isinstance(inputValue, str) or isinstance(inputValue, unicode) or inputValue is None
		assert isinstance(inputURI, str) or isinstance(inputURI, unicode) or inputURI is None

		tempValue = FormatASCII(inputValue).replace('\t', '').strip().replace('|', ',').replace(';', '')
		if tempValue != '':
			self.termValue = tempValue

		tempURI = FormatASCII(inputURI)
		if tempURI != '':
			self.termURI = tempURI

		tempURI = tempURI.rsplit('#')[-1].rsplit('/')[-1]
		if 'ncbi_gene' in self.termURI:
			tempURI = 'GENE_' + tempURI
		if tempURI != '':
			self.shortURI = tempURI

	def exportTuple(self):
		# Export values as tuple
		return self.termValue, self.shortURI, self.termURI


class GemmaOntTerm(BasicOntTerm):
	# Class structure of Gemma's Ontology Term

	def __init__(self, inputTerm):
		# Initialize
		assert isinstance(inputTerm, OntologyTerm)
		super(GemmaOntTerm, self).__init__()
		self.importValues(inputValue = inputTerm.term, inputURI = inputTerm.uri)


class ExperimentTag(object):
	# Class structure of Gemma's experiment tag

	def __init__(self, inputTerm):
		# Initialize
		assert isinstance(inputTerm, AnnotationValueObject)
		self.termCategory = BasicOntTerm()
		self.termValue = BasicOntTerm()

		self.id = inputTerm.id
		self.termCategory.importValues(inputValue = inputTerm.className, inputURI = inputTerm.classUri)
		self.termValue.importValues(inputValue = inputTerm.termName, inputURI = inputTerm.termUri)
		self.termType = FormatASCII(inputTerm.objectClass)
		self.evidence = FormatASCII(inputTerm.evidenceCode)


class ExperimentTagList(object):
	# Class structure of Gemma's experiment tag list

	def __init__(self, inputList):
		# Initialize
		assert isinstance(inputList, Iterable) or inputList is None

		if inputList is None or len(inputList) == 0:
			self.list = []

		tempList = filter(lambda x: x is not None, inputList)
		self.list = map(lambda x: ExperimentTag(x), tempList)
		self.list.sort(key = lambda x: x.termValue.termURI)


class CharacteristicObject(object):
	# Class structure of Gemma's Characteristic Object (Similar to Experiment Tag, excluding termType)

	def __init__(self, inputObject):
		# Initialize
		assert isinstance(inputObject, Characteristic)
		self.termCategory = BasicOntTerm()
		self.termValue = BasicOntTerm()
		self.evidence = 'NA'

		self.id = inputObject.id
		self.termCategory.importValues(inputValue = inputObject.category, inputURI = inputObject.categoryUri)
		self.termValue.importValues(inputValue = inputObject.value, inputURI = inputObject.valueUri)

		if inputObject.evidenceCode is not None:
			self.evidence = FormatASCII(inputObject.evidenceCode.value)
