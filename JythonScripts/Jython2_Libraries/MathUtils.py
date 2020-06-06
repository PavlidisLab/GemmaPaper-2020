# Module for Math Utilities

# Python Imports
from PyVersion import PyCheckLenient
from collections import Iterable
from math import fsum

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


def Median(numericVector):
	# Calculates median value
	assert issubclass(type(numericVector), Iterable)

	numericVector = sorted(numericVector)
	sliceIndex = len(numericVector)/2

	if len(numericVector) == 2:
		# Special case for two element vectors
		return fsum(numericVector)/2
	elif len(numericVector) % 2 == 0:
		# Even number of elements
		return fsum(numericVector[sliceIndex: (sliceIndex - 2): -1])/2
	else:
		# Odd number of elements
		return numericVector[sliceIndex]


def Mean(numericVector):
	# Calculates mean value
	assert issubclass(type(numericVector), Iterable)

	return fsum(numericVector)/len(numericVector)
