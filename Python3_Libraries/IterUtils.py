# Module for Iterator Utilities

# Python Imports
from array import array
from PyVersion import PyCheckLenient

# Python Version Check
# Requirement: CPython 3.7.X
assert PyCheckLenient('CPython', '3', '7')


def RSlice(inputList, indexList):
	# R-style list slicing
	assert isinstance(inputList, list) or isinstance(inputList, array)
	assert isinstance(indexList, list)
	assert all(map(lambda x: isinstance(x, int), indexList))

	tempOutput = list(map(lambda x: inputList[x], indexList))
	return tempOutput
