# Module for Checking Python Version

# Python Imports
import platform


def PyCheckStrict(executable = 'CPython', first = '3', second = '7', third = '5'):
	# Python version check function
	# NOTE: Requires exact match
	pyImplementation = platform.python_implementation()
	pyVersion = platform.python_version_tuple()
	return pyImplementation == executable and pyVersion == (first, second, third)


def PyCheckLenient(executable = 'CPython', first = '3', second = '7'):
	# Python version check function
	# NOTE: Skips "patch level"
	pyImplementation = platform.python_implementation()
	pyVersion = platform.python_version_tuple()[0:2]
	return pyImplementation == executable and pyVersion == (first, second)
