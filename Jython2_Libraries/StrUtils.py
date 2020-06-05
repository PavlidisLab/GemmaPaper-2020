# Module for String Utilities

# Python Imports
from PyVersion import PyCheckLenient
from collections import Iterable

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


def FormatASCII(obj):
	# Convenience function for converting to R-friendly format
	if obj is None:
		return 'NA'
	elif isinstance(obj, unicode):
		return obj.encode('ascii', 'ignore')
	elif isinstance(obj, str):
		return obj
	elif isinstance(obj, bool):
		return str(obj).upper()
	elif issubclass(type(obj), Iterable):
		# Non-string Iterables should be joined first
		raise TypeError
	else:
		return str(obj)
