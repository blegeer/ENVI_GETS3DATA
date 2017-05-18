# ENVI_GETS3DATA
ENVI extension to get single files or "folders" from an S3 bucket and open them in ENVI

This utility utilizes allows an AWS user to download data from S3 buckets onto a local machine and open that data into ENVI (single file) only. This uses the IDL-Python bridge to call Python scripts that utilize the boto module for working with AWS. 

## Installation
1. Make sure that a version of Python (2.7 or 3.4+) exist on your machine. 
2. Append the location of the python.exe executable (Windows) to your PATH environment variable. 
     For example PATH=%PATH%;c:\Python27\ArcGIS10.4 if you use the python that comes with ArcGIS 10.4
     NOTE: Be sure that the python you are using is compiled with the same bit-depth as the IDL that you are running. 
     For ArcGIS versions - you might need to run 32-bit ENVI+IDL for the bridge to work
3. Start IDL and check that the python is working
   ```Python
   IDL> >>>
   IDL> import sys
   IDL> sys.version
   '2.7.10 (default, May 23 2015, 09:40:32) [MSC v.1500 32 bit (Intel)]'
   ```
4. Make sure the boto python module is installed. Installation files are included - see http://boto.cloudhackers.com/en/latest/getting_started.html for some nice installation instructions. 
5. Verify boto module installation
   ```Python
   IDL> >>>
   IDL> import boto
   ```
6. Install extension files in the local extensions directory
   Determine your extensions dir
   ```IDL
   IDL> v = e.preferences["directories and files:extensions directory"].value
   C:\Users\myname\.idl\envi\extensions5_3\
   Copy envi_gets3data.pro and cso_s3utils.py to this directory
   
7. Restart ENVI
8. Run the extension from the "Extensions" folder in the ENVI toolbox. 

![Plugin Start](https://github.com/blegeer/ENVI_GETS3DATA/blob/master/ScreenShot1.png "Blank Startup")
