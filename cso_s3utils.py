# CSO_S3Utils
#
# Beau Legeer - DigitalGlobe

from boto.s3.connection import S3Connection
import os

def getS3FolderList(bucketName, folder, accessKey, secretKey):

# get a list of "folders" within a key
# folder must be in the form
# key1/key2/
# must have the leading slash and must be fully qualified

    folderList = []
        
    conn = S3Connection(accessKey,secretKey)
    bucket = conn.get_bucket(bucketName)
    nObj = 0
    for key in bucket.list(prefix=folder, delimiter='/'):
        nObj = nObj+1
        keyName = key.name.encode('utf-8')
        if (keyName.endswith('/')):
            if (keyName != folder):
                folderList.append(keyName)
        

    # print "Number of Objects in "+bucketName+": "+str(nObj)
    return(folderList)

def getS3FileList(bucketName, folder, accessKey, secretKey):

# folder must be in the form
# dir1/dir2/
# must have the leading slash and must be fully qualified

    fileList = []
    
    conn = S3Connection(accessKey,secretKey)
    bucket = conn.get_bucket(bucketName)
    nObj = 0
    for key in bucket.list(prefix=folder, delimiter='/'):
        nObj = nObj+1
        keyName = key.name.encode('utf-8')
        if (not keyName.endswith('/')):
            if (keyName != folder):
                fileList.append(keyName)
        

    # print "Number of Objects in "+bucketName+": "+str(nObj)
    return(fileList)


def getKeyToFile(bucketName, keyName, fileName, accessKey, secretKey):
    
    
    conn = S3Connection(accessKey,secretKey)
    bucket = conn.get_bucket(bucketName)
    key = bucket.get_key(keyName)
    key.get_contents_to_filename(fileName)
    
