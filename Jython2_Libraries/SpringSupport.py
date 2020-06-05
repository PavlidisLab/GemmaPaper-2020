# Module for Generating Spring Context (Gemma-specific)

# Python Imports
from __future__ import print_function
from PyVersion import PyCheckLenient

# Java Imports
from ubic.gemma.persistence.util import SpringContextUtil

# Python Version Check
# Requirement: Jython 2.7.X (CPython 2.7.X Bypass added for PyCharm Debugging)
assert PyCheckLenient('Jython', '2', '7') or PyCheckLenient('CPython', '2', '7')


class SpringSupport:
	# Spring session object storing Gemma authentication tokens
	
	def __init__(self, username = None, password = None):
		# Initialize Spring session and acquire authentication tokens
		self.appCtx = SpringContextUtil.getApplicationContext(False, False, ["classpath*:ubic/gemma/cliContext-component-scan.xml"])
		manAuthServ = self.appCtx.getBean('manualAuthenticationService')
		
		if username is None and password is None:
			manAuthServ.authenticateAnonymously()
			print('Logged in as Anonymous')
		
		else:
			authSuccess = manAuthServ.validateRequest(username, password)
			
			if not authSuccess:
				print('ERROR: Invalid Username/Password')
				raise ValueError('Invalid Username/Password')
			else:
				print('Logged in as {0}'.format(username))
	
	def getBean(self, beanName):
		# Accessing exposed objects
		return self.appCtx.getBean(beanName)
	
	def shutDown(self):
		# End Spring session
		self.appCtx.close()
