# Module for Lazy-Pickling with Compression (open + pickle + xz)

# Python Imports
import pickle
import shlex
import subprocess
from PyVersion import PyCheckLenient

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


def XZWrite(obj, path, thread = 16, compression = 6):
	# Convenience wrapper for writing pickled-compressed objects
	assert isinstance(path, str)
	assert isinstance(thread, int)
	assert isinstance(compression, int)
	assert 0 <= compression <= 9
	
	tempFile = open(path, mode = 'wb')
	tempPickle = pickle.dumps(obj = obj, protocol = 2)
	tempCommand = shlex.split('xz -z -T {0} -{1} -c'.format(thread, compression))
	tempPopen = subprocess.Popen(tempCommand, stdin = subprocess.PIPE, stdout = tempFile)
	tempResponse = tempPopen.communicate(tempPickle)
	tempFile.close()


def XZRead(path):
	# Convenience wrapper for reading pickled-compressed objects
	assert isinstance(path, str)
	tempFile = open(path, mode = 'rb')
	tempCommand = shlex.split('xz -d -c')
	tempPopen = subprocess.Popen(tempCommand, stdin = tempFile, stdout = subprocess.PIPE)
	tempPickle = tempPopen.communicate()[0]
	tempFile.close()
	tempObject = pickle.loads(tempPickle)
	return tempObject
