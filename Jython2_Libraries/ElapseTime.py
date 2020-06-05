# Module for Time-stamping

# Python Imports
from PyVersion import PyCheckLenient
import datetime

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


class ElapseTime:
	# ElapseTime records the time of initialization and returns subsequent requests for time elapsed.

	def __init__(self):
		# Initialize
		self.initial = datetime.datetime.now()
		self.format = '%d %b %Y (%a) - %I:%M:%S %p'

	def getBeginStamp(self):
		# Return initial timestamp
		currentStamp = self.initial.strftime(self.format)
		return 'Script Begin: {0}'.format(currentStamp)

	def getEndStamp(self):
		# Return elapse timestamp and time difference
		currentTime = datetime.datetime.now()
		currentStamp = currentTime.strftime(self.format)

		timeDelta = currentTime - self.initial
		dMinute, dSecond = divmod(timeDelta.seconds, 60)
		dHour, dMinute = divmod(dMinute, 60)
		dDay = timeDelta.days
		timeStamp = 'Total Time: {0} day(s), {1} hour(s), {2} minute(s), {3} second(s)'.format(dDay, dHour, dMinute, dSecond)
		return 'Script End: {0}\n{1}'.format(currentStamp, timeStamp)
