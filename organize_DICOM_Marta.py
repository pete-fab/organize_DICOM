import os.path

def RenameDICOM(rootDir):
    if os.path.exists(rootDir):
        return True
    elif not os.path.exists(rootDir):
        return False
        print str('Given directory does not exist: ', rootDir, '. Give me something real to work on.')
