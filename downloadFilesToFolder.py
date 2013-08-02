#!/usr/bin/env python

__author__ = "Albert Eloyan"
__email__ = "albert.eloyan@gmail.com"

"""
	Basically a DEU script that wraps the file upload mechanization in uploadFilesToTagged.pl
	This script will download a bunch of files from the links provided in the input file;
	Upload the photos to a tagged account (specified in the accompanying perl script);
	Save the URLs of the upload into an output file in php array format;
"""

#This script will download a bunch of files from the web into a folder
import urllib
import urllib2
import os
import popen2
import commands
import subprocess
import sys

#constants
DEBUG_MSGS = False
INPUT_FILE_PATH = '/path/to/input.txt'
OUTPUT_FILE_NAME = 'outputFile.txt'

def downloadFilesToFolder():

	"""
		This is the file downloader function
		Calls: the image uploader
	"""

	#importing link text file into python list for convenience
	with open(INPUT_FILE_PATH) as f:
	    listOfLinks = f.readlines()

	#placeholder variable to hold perl script's output
	singleFileOutput = ""

	#preparing the output file that will contain new links
	outputFile = open(OUTPUT_FILE_NAME, 'w')
	outputFile.write('array(')
	outputFile.close()

	#two types of errors ara packaged into a tuple of format (networkErrors, tooSmallEerrors)
	errNumsTuple = uploadImagesUsingUrl(listOfLinks, OUTPUT_FILE_NAME)

	print "Network errors: ", len(errNumsTuple[0])
	print "TOO_SMALL errors: ", len(errNumsTuple[1])

	#Re-running for failed images:
	decision = raw_input("Re-run for network errors? (y/n)\n")

	if decision == 'y' or decision == 'Y' or decision == 'Yes' or decision == 'yes':
		#re-calling uploadImagesUsingUrl with new listOfLinks using python list comprehension
		errNumsTuple = uploadImagesUsingUrl([listOfLinks[i] for i in errNumsTuple[0]],
																		 OUTPUT_FILE_NAME)
	else:
		print "Exiting..."

def uploadImagesUsingUrl(listOfLinks, OUTPUT_FILE_NAME):

	"""
		Wrapper for the mechanization script. Opens subprocesses and stores return value
	"""

	networkErrNums = []
	tooSmallErrNums = []

	outputFile = open(OUTPUT_FILE_NAME, 'a')

	for index, oldImageLink in enumerate(listOfLinks):

		try:
			#downloading file from link into directory 
			u = urllib.urlretrieve(oldImageLink, 'orphans/image' + str(index))

	 		sys.stdout.write("RUN NUMBER: " + str(index) + "...................")

	 		#piping the file into a perl subprocess
			pipe = subprocess.Popen(['perl', 'uploadFilesToTagged.pl', 'orphans/image' + str(index)], stdout=subprocess.PIPE)
			singleFileOutput = pipe.stdout.read()
		 	pipe.stdout.close()

		 	if singleFileOutput.rstrip() == 'FAIL_SMALL' or singleFileOutput.rstrip() == '':

		 		print "FAIL_SMALL\n"
		 		tooSmallErrNums.append(index)

		 	elif singleFileOutput.rstrip() == 'FAIL_GET':

		 		print "FAIL_GET\n"
		 		networkErrNums.append(index)

		 	elif singleFileOutput.rstrip() == 'FAIL_POST':

		 		print "FAIL_POST\n"
		 		networkErrNums.append(index)

		 	else:
		 		#adding to output file
	 		 	if index != len(listOfLinks)-1:
	 			 	outputFile.write('"' + oldImageLink.rstrip() + '"' + ' => ' 
	 			 					 '"' + singleFileOutput.rstrip() + '", \n')
	 			elif len(networkErrNums)==0:
	 				outputFile.write('"' + oldImageLink.rstrip() + '"' + ' => ' 
	 								 '"' + singleFileOutput.rstrip() + '")')
	 			else:
	 				pass

	 		 	print "OK\n"

		except IOError:
			networkErrNums.append(index)
			print "FAILED TO DOWLOAD IMAGE: ", index

	return (networkErrNums, tooSmallErrNums)

downloadFilesToFolder()