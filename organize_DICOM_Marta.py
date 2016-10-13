import os
import numpy as np
import scipy.linalg

#% Example use: RenameDicom('C:\Root\Directory\With\DICOM\files')
#% Folder structure can be formed by adding addSubFolder functions()

#function RenameDICOM(rootDir)
#    if ~exist(rootDir, 'dir')
#        error(strcat('Given directory does not exist: ', rootDir, ' . Give me something real to work on.'));
#    end
#    counter = 0;
#    rootDir = sanitizeDir(rootDir);
#    flattenFolderHierarchy(rootDir);

#% Commonly used rules:
#% RequestingPhysician - sbXX
#% StudyComments - sX
#% ReferringPhysicianName - Project Name
#% Each subfolder function call creates another subfolder level
#% counter = addSubFolder(rootDir, counter, 'ReferringPhysicianName', '', '', true);
#% project name folder
#% counter = addSubFolder(currentDir, counter, 'RequestingPhysician', '', '', false);
#% Logos setting
#    counter = addSubFolder(rootDir, counter, 'StudyDate', '', '', true); % QA setting / KUL setting / LOGOS setting
#    counter = addSubFolder(rootDir, counter, 'SeriesDescription', 'SeriesNumber', 'PatientName', true); % QA setting / KUL setting / LOGOS setting
#    disp(strcat(num2str(counter + 3), '. Renaming files'));

#% renameFiles(Dir, 'RequestingPhysician;SeriesDescription', 'IMA', true);
#% rename all the files in the directory, KUL / LOGOS setting
#    renameFiles(rootDir, 'StudyDescription;RequestingPhysician', 'IMA', true); % rename all the files in the directory, QA setting
#% Below are listed filenaming templates
#% Siemens Template: 'PatientName;StudyDescription;SeriesNumber;InstanceNumber', 'IMA'
#% Domagalik Template: 'RequestingPhysician;SeriesDescription', 'IMA'
#% Example Template: 'SeriesDescription;PatientName;PatientID;RequestedProcedureDescription', 'DCM'
#end

def RenameDICOM(rootDir):
    if not os.path.exists(rootDir):
        print str('Given directory does not exist: '+ rootDir + '. Give me something real to work on.')
        return False
    count = 0
    rootDir = sanitizeDir(rootDir)
    flattenFolderHierarchy(rootDir)

    count = addSubFolder(rootDir, count, StudyDate, '', '', True)
    count = addSubFolder(rootDir, count, SeriesDescription, SeriesNumber, PatientName, True)
    print str(str(count + 3) + '. Renaming files')
    return renameFiles(rootDir, StudyDescription, RequestingPhysician, IMA, True)


#    function   depth = addSubFolder(dir, depth, ruleString, differenceRuleString, commonRuleString, isCaps)
 #   disp(strcat(num2str(depth + 2), '. Adding subfolders according to the rule: ', ruleString));
  #  [dirList, dirListSize] = getCurrentDirList(dir, depth);
   # if (dirListSize == 0)
    #dirList(end+1).path = dir;
    #dirListSize =[0 1];
    #end
 #   CM =[]; % create Co Occurance Matrix for difference rules
#    for d = 1: dirListSize(2)
 #   currentDir = dirList(d).path;
  #  [fileList, fileListSize] = getFileList(currentDir);
   # for f = 1: fileListSize(1)
               #% get subfolder folder Name
 #   currentFilePath = os.path.join(currentDir, fileList(f).name);
#    info = dicominfo(currentFilePath);
    #[CM, newDir] = createSubFolder(currentDir, info, ruleString, differenceRuleString, commonRuleString, isCaps, CM);
                #% move file to folder
   # newFilePath = strcat(newDir, fileList(f).name);
  #  renameThisFile(currentFilePath, newDir, fileList(f).name);
 #   end
#    end
   # dirSplit = strsplit(dir, '/');
  #  newDirSplit = strsplit(newDir, '/');
 #   depth = size(newDirSplit) - size(dirSplit);
#    end

def addSubFolder(dir, depth, ruleString, differenceRuleString, commonRuleString, isCaps):
    print str(str(depth + 2) + '. Adding subfolders according to the rule: ' + ruleString)
    [dirList, dirListSize] = getCurrentDirList(dir, depth)
    if dirListSize == 0:
        dirList[-1] = dir #nie rozumiem dirList(end+1).path
        dirListSize = np.hstack((0,1))
    CM = []
    for d in range(1,dirListSize(2)):
        currentDir = dirList[d] #os.path.realpath(dirList(d))???
        [fileList, fileListSize] = getFileList(currentDir)
        for f in range(1,fileListSize(1)):
            currentFilePath = os.path.join(currentDir, os.path.basename(fileList[f]))
            info = dicominfo(currentFilePath)
            [CM, newDir] = createSubFolder(currentDir, info, ruleString, differenceRuleString, commonRuleString, isCaps, CM)
            newFilePath = str(newDir + os.path.basename(fileList[f]))
            renameThisFile(currentFilePath, newDir, os.path.basename(fileList[f]))
    dirSplit = dir.split('/')
    newDirSplit = newDir.split('/')
    depth = newDirSplit.shape - dirSplit.shape
    return depth

#% returns directory of the script
    #function Dir = getScriptDir()
    #   fullPath = mfilename('fullpath');
    #   [Dir, ~, ~] = fileparts(fullPath);
#end
def getScriptDir():
    return os.path.dirname(os.path.realpath(__file__))


# % returns list of files in the given directory
# function [list,listSize] = getFileList(Dir)
#    DirResult = dir( Dir );
#    list = DirResult(~[DirResult.isdir]); % select files
#    listSize = size(list);
# end


def getFileList(dir):
    list = os.listdir(dir)
    listSize = len(list)
    return [list, listSize]

# % returns list of folders in the given diretory
# function [list,listSize] = getFolderList(Dir)
#    DirResult = dir( Dir );
#    list = DirResult([DirResult.isdir]); % select folders
#    list = selectVisibleDirectories(list);
#    listSize = size(list);
# end

def getFolderList(dir):
    list = os.walk(dir)
        x[0] for x in os.walk(dir)
    ListSize = len(list)
    return [list, listSize]

#% renames files in the given directory according to a given rule
#% @variables

#% currentDir - the directory with the files
#% namingRule - a string consisting of semi - colon(;) separated dicomInfoTags
#% fileType - string with file type: 'IMA', 'DCM', 'DICOM'
#% isCaps - true / false, should the names be capitalised or small letters
#function renameFiles(currentDir, namingRule, fileType, isCaps)
#[currentFileList, currentListSize] = getFileList(currentDir);
#% calculate number of digits in number
#numSize = numel(num2str(currentListSize(1)));

#% format number string
#formatString = strcat('%0', num2str(numSize), 'd');

#for k = 1: currentListSize(1)

#% read DICOM info
#currentFilePath = os.path.join(currentDir, currentFileList(k).name);
#info = dicominfo(currentFilePath);

#newFileName = getNewDicomName(info, namingRule, fileType, isCaps, formatString, info.InstanceNumber);
#newFilePath = strcat(currentDir, newFileName);

#renameThisFile(currentFilePath, currentDir, newFileName);
#end

#[dirList, dirListSize] = getFolderList(currentDir);
#for k = 1: dirListSize
#childDir = strcat(currentDir, '/', dirList(k).name, '/');
#renameFiles(childDir, namingRule, fileType, isCaps)
#end

def RenameFiles(currentDir, namingRule, fileType, isCaps):
    [currentFileList, currentListSize] = getFileList(currentDir)
    numSize = size(str(currentListSize(1)))
    formatString = str('%0' + str(numSize) + 'd')
    for k in range(0,currentListSize(1)):
        currentFilePath = os.path.join(currentDir, currentFileList(k).__name__)
        info = dicominfo(currentFilePath)
        newFileName = getNewDicomName(info, namingRule, fileType, isCaps, formatString, info.InstanceNumber)
        #nie wiem na co zamienić info. w Pythonie
        newFilePath = str(currentDir + newFileName)
        renameThisFile(currentFilePath,currentDir,newFileName)
    [dirList, dirListSize] = getFolderList(currentDir)
    for k in range(0,dirListSize):
        childDir = str(currentDir + '/' + dirList(k).__name__ + '/')
        renameFiles(childDir, namingRule, fileType, isCaps)


#%returns new name for a DICOM file according to given rules
#function newFileName = getNewDicomName(dicomInfo, namingRule, #fileType, isCaps, formatString, fileNumber)
#    CoreStr = ruleString2dataString(dicomInfo, namingRule, isCaps);
#    newFileName = strcat( CoreStr,...
#        '_',sprintf(formatString,fileNumber),... % e.g. 00045
#        '.',...
#       fileType... % e.g. .DICOM, .DCM
#        );
#end

def getNewDicomName(dicomInfo, namingRule, fileType, isCaps, formatString, fileNumber):
    CoreStr = ruleString2dataString(dicomInfo, namingRule, isCaps)
    newFileName = str(CoreStr + "_" + str(formatString,fileNumber) + "." + fileType)
    return newFileName

#% Create new subdirectory directory based on given rules
#% @variables:
#% - dir - parent full diretory
#% - info - DICOM info of the file to be moved to subdirectory
#% - ruleString - rule for creating subfolder
#% - differenceString - rule for distinguishing similarity between DICOM
#% - commonRuleString - rule for preventing the differenceString being
#% applied
#% - isCaps - are the resulting strings to be in capital or small letters
#% - coOccuranceMatrix - matrix holding the data for applying difference and
#% common rules
#function[coOccuranceMatrix, newDir] = createSubFolder(dir, info, ruleString, differenceRuleString, commonRuleString, isCaps, coOccuranceMatrix)
#    isNewDirFound = false;
#    k = 0;
#    folderName = ruleString2dataString(info, ruleString, isCaps);
#    diffStr = ruleString2dataString(info, differenceRuleString, isCaps);
#    commonStr = ruleString2dataString(info, commonRuleString, isCaps);
#% if differenceRuleString is set then the folders will need to change.
#% if (~isempty(differenceRuleString)) % & & strcmpi(folderName, restrictDiffRuleString) )
#% folderName = strcat( folderName, '_0' );
#% end

#    while (~isNewDirFound)
#        if (k ~= 0 )
#            folderName = adjustFolderName(folderName);
#end

#        newDir = strcat(dir, '/', folderName, '/');
#        newDir = sanitizeDir(newDir);
#        coOccuranceMatrix = addToCoOccuranceMatrix(coOccuranceMatrix, diffStr, commonStr, newDir);
#        if (exist(newDir, 'dir'))
#            if (isempty(differenceRuleString))
#            return;
#%if differenceRuleString is empty add to specified directory
#% the differences / similarities between files are ignored
#    end
#            if isImageAllowedIn(coOccuranceMatrix, diffStr, commonStr, newDir)
#                return; % if the files inside have the same characteristic return
#    end
#            k = k + 1;
#% do the while loop again
#        else
#            isNewDirFound = true;
#            mkdir(newDir);
#end
#end
#end

def createSubFolder(dir, info, ruleString, differenceRuleString, commonRuleString, isCaps, coOccuranceMatrix):
    isNewDirFound = False
    k = 0
    folderName = ruleString2dataString(info, ruleString, isCaps)
    diffStr = ruleString2dataString(info, differenceRuleString, isCaps)
    commonStr = ruleString2dataString(info, commonRuleString, isCaps)
    while not isNewDirFound:
        if k != 0:
            foldername = adjustFolderName(folderName)
        newDir = str(dir + '/' + folderName + '/');
        newDir = sanitizeDir(newDir);
        coOccuranceMatrix = addToCoOccurenceMatrix(coOccuranceMatrix, diffStr, commonStr, newDir);
        if os.path.exists(newDir, 'dir'):
            if not differenceRuleString:
                return [coOccuranceMatrix, newDir]
            if isImageAllowedIn(coOccuranceMatrix, diffStr, commonStr, newDir):
                return [coOccuranceMatrix, newDir]
            k = k + 1
        else:
            isNewDirFound = True
            os.makedirs(newDir)
    return [coOccuranceMatrix, newDir]

# Adds the data to Co-Occurance Matrix if it is not already there
# @variables:
# CM - the matrix,
# differenceRuleValue - data value
# commonRuleValue - data value
# pathName - data value

#function CM = addToCoOccuranceMatrix(CM,differenceRuleValue,commonRuleValue,pathName)
#    if #~isExistInCoOccuranceMatrix(CM,commonRuleValue,pathName)
#        CM(end+1).differenceRuleValue = #differenceRuleValue;
#        CM(end).commonRuleValue = commonRuleValue;
#        CM(end).folderName = pathName;
#    end
#end

def addToCoOccurenceMatrix(CM, differenceRuleValue, commonRuleValue, pathName):
    if not isExistInCoOccuranceMatrix(CM,commonRuleValue,pathName):
        CM.append(np.array(differenceRuleValue))
        CM.append(np.array(commonRuleValue))
        CM.append(np.array(pathName))
    return CM

#% Verifies whether the data exists in Co-Occurance Matrix
#% @variables:
#% CM - the matrix,
#% commonRuleValue - data value
#% pathName - data value
#function TF = isExistInCoOccuranceMatrix(CM,commonRuleValue, pathName)
#    TF = false;
#    for i = 1 : size(CM,2)
#        if strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
#            TF = true;
#            break;
#        end
#    end
#end

def isExistInCoOccuranceMatrix(CM, commonRuleValue, pathName):
    TF = False
    for i in range(1, np.shape(CM)[1]):
        if str(os.path.abspath(CM[i]) == str(pathName) and str(CM[i].commonRuleValue) == str(commonRuleValue):
            # nie potrafię zamienić CM[i].commonRuleValue)
            TF = True
    return TF

#% Verifies by using Co-Occurance Matrix whether the image can be inserted
#% into the given pathName considering the rules
#% @variables:
#% @variables:
#% CM - the matrix,
#% differenceRuleValue - data value
#% commonRuleValue - data value
#% pathName - data value
#function TF = isImageAllowedIn(CM,differenceRuleValue,commonRuleValue,pathName)
#    TF = false;
#    for i = 1 : size(CM,2)
#        if strcmp(CM(i).differenceRuleValue,differenceRuleValue) && strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
#            TF = true;
#            break;
#        end
#    end
#end


def isImageAllowedIn(CM,differenceRuleValue,commonRuleValue,pathName):
    TF = False
    for i in range(1, np.shape(CM)[1]):
    if str(CM[i].differenceRuleValue) == str(differenceRuleValue) and str(CM[i].folderName) == str(pathName) and str(CM[i].commonRuleValue) == str(commonRuleValue):
        TF = True
    return TF

#% function called whenever differenceRuleString causes conflicts. Then
#% folder names get appended numbers to differentiate between them.
#% function called whenever differenceRuleString causes #conflicts. Then
#% folder names get appended numbers to differentiate #between them.
#function newFolderName = adjustFolderName(folderName)
#    splitCell = strsplit(folderName,'_');
#    num = str2num( splitCell{end} );
#
#    if( isempty(num) || ~isfinite(num) || (num==-999) )
#        % not a valid number, append _1 at the end of the new folder name
#        newFolderName = strcat(folderName,'_1');
#    else
#        % number, increment it
#        num = num + 1;
#        splitCell{end} = num2str(num);
#        newFolderName = strjoin(splitCell,'_');
#    end

def adjustFolderName(folderName):
    splitCell = str.split(folderName, '_')
    num = float(splitCell[-1])
    if not num or not np.isfinite(num) or (num == -999):
        newFolderName = str(folderName + '_1')
    else:
        num = num + 1
        splitCell[-1] = str(num)
        newFolderName = str(splitCell + '_')
    return newFolderName

#% Converts provided rule string into folder compatible form
#% @variables:
#% - info - uses the provided DICOM file info
#% - ruleString - needs to be semi - colon separated for multiple info fields
#% - isCaps - determines whether the letters should be upper or lower case
#function dataString = ruleString2dataString(info, ruleString, isCaps)
#   fields = strsplit(ruleString, ';');
#   dataString = '';
#   if strcmp(fields{1}, '')
#       return;
#end
#    fieldsSize = size(fields);
#   for k = 1: fieldsSize(2)
#       if (k > 1)
#           dataString = strcat(dataString, '_');
#end
#        if isfield(info, fields{k} ) % Check if ths field exists.If it is empty, it may not exist
#            fieldVal = getField(info, fields{k} );
#        elseif(strcmp(fields {k}, 'ImageComments') | | strcmp(fields {k}, 'StudyComments') )
#            nameString = getField(info, 'PatientName');
#            fieldVal = getField(info, 'StudyDate');
#            disp(strcat('The StudyComment is missing for image taken on ', fieldVal, ' for ', nameString));
#        elseif(strcmp(fields {k}, 'RequestingPhysician') )
#            dateString = getField(info, 'StudyDate');
#            fieldVal = getField(info, 'PatientName');
#            disp(strcat('The RequestingPhysician is missing for image taken on ', dateString, ' for ', fieldVal));
#        else
#            dateString = getField(info, 'StudyDate');
#            fieldVal = getField(info, 'PatientName');
#            disp(strcat('The', fields{k}, ' is missing for image taken on ', dateString, ' for ', fieldVal));
#        end
#        fieldValString = parseFieldValue(fieldVal);
#        dataString = strcat(dataString, fieldValString);
#    end
#    dataString = applyCaps(dataString, isCaps);
#    dataString = sanitizeString(dataString);
#end

def ruleString2dataString(info, ruleString, isCaps):
    fields = ruleString.split(';')
    dataString = ''
    if str(fields[1]) == '':
        return dataString
    fieldSize = fields.shape #czy len(fields)?
    for k in range(0, fieldSize[1]):
        if k > 1:
            dataString = str(dataString + '_')
        if isField(info, fields[k]):
            fieldVal = getField(info, fields[k])
        elif (str(fields[k]) == 'ImageComments') or (str(fields[k]) == 'StudyComments'):
            nameString = getField(info, 'PatientName')
            fieldVal = getField(info, 'StudyDate')
            print str('The StudyComment is missing for image taken on ' + fieldVal + ' for ' + nameString)
        elif str(fields[k] == 'RequestingPhysician'):
            dateString = getField(info, 'StudyDate')
            fieldVal = getField(info, 'PatientName')
            print str('The' + fields[k] + ' is missing for image taken on ' + dateString + ' for ' + fieldVal)
        else:
            dateString = getField(info, 'StudyDate')
            fieldVal = getField(info, 'PatientName')
            print str('The' + fields[k] + ' is missing for image taken on ' + dateString + ' for ' + fieldVal)
        fieldValString = parseFieldValue(fieldVal)
        dataString = str(dataString + fieldValString)
    dataString = applyCaps(dataString, isCaps)
    dataString = sanitizeString(dataString)
    return dataString

#function dataString = applyCaps(dataString, isCaps)
#    if (isCaps)
#        dataString = upper(dataString);
#    else
#        dataString = lower(dataString);
#end
#end

def applyCaps(dataString, isCaps):
    if isCaps:
        dataString = dataString.upper()
    else:
        dataString = dataString.lower()
    return dataString

#% Overrides Matlab getfield() function. It adds verification whether the field exists to it
#function result = getField(structure, fieldName)
#    if isfield(structure, fieldName)
#        fieldVal = getfield(structure, fieldName);
#        if strcmp(fieldName, 'PatientName')
#            fieldVal = strcat(getField(fieldVal, 'FamilyName'), '_', getField(fieldVal, 'GivenName'));
#        elseif(strcmp(fieldName, 'ReferringPhysicianName') | | strcmp(fieldName, 'OperatorName')...
#           | | strcmp(fieldName, 'PerformingPhysicianName') | | strcmp(fieldName, 'RequestingPhysician'))
#             fieldVal = getField(fieldVal, 'FamilyName');
#        end
#        result = fieldVal;
#    else
#        result = '';
#end

def getField(structure, fieldName):
    if isField(structure, fieldName):
        fieldVal = getField(structure, fieldName)
        if str(fieldName) == str('PatientName'):
            fieldVal = str(getField(fieldVal, 'FamilyName') + '_' + getField(fieldVal, 'GivenName'))
        elif (str(fieldName) == str('ReferringPhysicianName') or str(fieldName) == str('OperatorName') or
        str(fieldName) == str('PerformingPhysicianName') or str(fieldName) == str('RequestingPhysician')):
            fieldVal = getField(fieldVal, 'FamilyName')
        result = fieldVal
    else:
        result = ''
    return result

#% The values returned from DICOM info structure are not always suitable for
#% naming files or folders.This parser makes them compatible with the standard.

#function string = parseFieldValue(fieldValueString)
#    if (~ischar(fieldValueString))
#      if (isnumeric(fieldValueString))
#            fieldValueString = num2str(fieldValueString);
#    else % ~string & ~number
#    error(strcat('fieldValueString in parseFieldValue() is not a', ...
#    'string nor a number. Adjust script to account for this.', ...
#    'Notify piotr.faba@uj.edu.pl about this error.') );
#    end
#end
#    fieldValueString = strrep(fieldValueString, '^', '_');
#    fieldValueString = strrep(fieldValueString, '.', '_');
#    fieldValueString = strrep(fieldValueString, ' ', '_');
#    fieldValueString = strrep(fieldValueString, '-', '_');
#    string = fieldValueString;
#end

def parseFieldValue(fieldValueString):
    for x in fieldValueString:
        if type(x) is not str:
            if x.isdigit:
                fieldValueString = str(fieldValueString)
        else:
            os.error(str('fieldValueString in parseFieldValue() is not a' + 'string nor a number. Adjust script to account for this.' + 'Notify piotr.faba@uj.edu.pl about this error.'))
    fieldValueString = fieldValueString.replace(fieldValueString, '^', '_')
    fieldValueString = fieldValueString.replace(fieldValueString, '.', '_')
    fieldValueString = fieldValueString.replace(fieldValueString, ' ', '_')
    fieldValueString = fieldValueString.replace(fieldValueString, '-', '_')
    string = fieldValueString
    return string



# % Get list of subdirectories of given dir
# % if $depth ~= 'a', return all directories
# % if $depth is specified, return directories for required child depth.
# function [list,listSize] = getCurrentDirList(dir,depth)
#  if( ~strcmp(depth,'a') )
#    depth = depth - 1;
# end
# list = [];
# [folderList, listSize] = getFolderList(dir);
# for i = 1 : listSize(1) %parfor
#  currentDir = strcat(dir,'/',folderList(i).name);

# if( strcmp(depth,'a') || depth == 0 )
#   list(end+1).path = currentDir;
# end

# childList = getCurrentDirList(currentDir,depth);
# list = [list, childList];
# end
# listSize = size(list);
# end

def getCurrentDirList(dir,depth):
    if not str(depth) == str('a'):
        depth = depth -1
    list = []
    [folderList, listSize] = getFolderList(dir)
    for i in range(0, listSize(1)):
        currentDir = str(dir + '/' + os.path.basename(folderList(i)))
        if str(depth) == str('a') or depth == 0:
            list.append(currentDir) # os.path.abspath(list).append(1) ???
        childList = getCurrentDirList(currentDir,depth)
        list = np.hstack((list,childList))
    listSize = len(list)
    return [list, listSize]

#% Convert any folder hierarchy to:
#% root
#%  - subfolder1
#%  - subfolder2
#%  - subfolder3
#function flattenFolderHierarchy(dirName)
#   disp('1. Flattening the original directory');
#     recursiveMoveFilesToParent(dirName,dirName);
#%     %get the directories
#%     dirResult = dir(dirName);
#%     allDirs = dirResult([dirResult.isdir]);
#%     allSubDirs = selectVisibleDirectories( allDirs );
#%
#%     %rename them based on their contents
#%     for i = 1:length(allSubDirs)
#%         thisDir = allSubDirs(i);
#%         oldName = os.path.join(dirName,thisDir.name);
#%         recursiveMoveFilesToParent(oldName,oldName);
#%     end
#end

def flattenFolderHierarchy(dirName):
    print '1. Flattening the original directory'
    recursiveMoveFilesToParent(dirName, dirName)
    dirResult = dir(dirName)
    allDirs = dirResult(os.path.isdir(dirResult))
    allSubDirs = selectVisibleDirectories(allDirs)
    for i in range(1, len(allSubDirs)):
        thisDir = allSubDirs(i)
        oldName = os.path.join(dirName,os.path.basename(thisDir))
        recursiveMoveFilesToParent(oldName,oldName)
    pass

#% Remove dot subdirectories '.' and '..'
#function dirResultStruct = selectVisibleDirectories(dirResultStruct)
#for i = length(dirResultStruct):-1:1
#if (strcmp(dirResultStruct(i).name, '..') | | strcmp(dirResultStruct(i).name, '.'))
#    dirResultStruct(i) = [];
#end
#end
#
#if (size(dirResultStruct, 2) == 0)
#    dirResultStruct = struct([]);
#end
#end

def selectVisibleDirectories(dirResultStruct):
    for i in range(len(dirResultStruct), 0, -1):
        if (str(os.path.abspath(dirResultStruct[i]) == str( '. .') or str(os.path.abspath(dirResultStruct[i]) == str(('.'))))):
            dirResultStruct[i] = []
    if (np.shape(dirResultStruct)[1] == 0):
        dirResultStruct = np.array([])
    return dirResultStruct

#% recursive function to change move filesto parent
#% removes the subfolders
#% moves all the files into paretnDir
#% E.g.:
#% parent folder:
#% - file1
#% - file2
#% - file3

#function recursiveMoveFilesToParent(dirName, parentDir)

%# move all the files
#   [allFiles, fileListLength] = getFileList(dirName);
#   for i = 1: fileListLength
#       thisFile = allFiles(i);
#       oldFilePath = os.path.join(dirName, thisFile.name);
#       if isDICOM(oldFilePath) & & ~strcmp(thisFile.name, 'DICOMDIR')
#           info = dicominfo(oldFilePath);
#           renameThisFile(oldFilePath, parentDir, strcat(info.SeriesInstanceUID, '_', num2str(info.InstanceNumber)));
#       else
#           delete(oldFilePath);
#       end
#   end

#   fileListLength = size(allFiles);

#% get the directories
#   dirResult = dir(dirName);
#   allDirs = dirResult([dirResult.isdir]);
#   allSubDirs = selectVisibleDirectories(allDirs);

#% remove extra folders
#   for i = 1:length(allSubDirs)
#       thisDir = allSubDirs(i);
#       dirPath = os.path.join(dirName, thisDir.name);
#       recursiveMoveFilesToParent(dirPath, parentDir);
#       rmdir(dirPath);
#   end
#end

def recursiveMoveFilesToParent(dirName, parentDir):
    [allFiles, fileListLength] = getFileList(dirName)
    for i in range(0,fileListLength):
        thisFile = allFiles(i)
        oldFilePath = os.path.join(dirName, os.path.basename(thisFile))
        if isDICOM(oldFilePath) and not str(os.path.basename(thisFile) == str('DICOMDIR')):
            info = dicominfo(oldFilePath)
            renameThisFile(oldFilePath, parentDir, str(info.SeriesInstanceUID + '_' + num2str(info.InstanceNumber))) #nie wiem jak zamienić info.
        else:
            del oldFilePath
    size(allFiles) = fileListLength
    dirResult = dir(dirName)
    allDirs = dirResult[os.path.isdir(dirResult)]
    allSubDirs = selectVisibleDirectories(allDirs)
    for i in range(1,len(allSubDirs):
        thisDir = allSubDirs[i]
        dirPath = os.path.join(dirName, os.path.basename(thisDir))
        recursiveMoveFilesToParent(dirPath, parentDir
        os.rmdir(dirPath)
    return recursiveMoveFilesToParent

#% Before renaming checks whether the old and the new path are not the same.
#% Also verifies that existing file with newFilePath will not be overwritten
#function renameThisFile(oldFilePath, newFileDir, newFileName)
#    newFileName = sanitizeString(newFileName);
#    newFilePath = strcat(newFileDir,'/',newFileName);
#    newFilePath = sanitizePath(newFilePath);
#    if exist(newFilePath,'file')
#        info = dicominfo(oldFilePath);
#        [~,~,ext] = fileparts(newFilePath);
#        newFilePath = strcat(newFileDir,'/',info.SOPInstanceUID,ext);
#        newFilePath = sanitizePath(newFilePath);
#    end
#    if( ~strcmp(oldFilePath,newFilePath) )
#        movefile(oldFilePath,newFilePath);
#    end
#end

def renameThisFile(oldFilePath, newFileDir, newFileName):
    newFileName = sanitizeString(newFileName)
    newFilePath = str(newFileDir + '/' + newFileName)
    newFilePath = sanitizePath(newFilePath)
    if os.path.exists(newFilePath):
        info = dicominfo(oldFilePath)
        _, filename = os.path.split(newFilePath)
        ext = filename.split('.')[2]
        newFilePath = str(newFileDir + '/' + info.SOPInstanceUID + ext) #nie wiem jak zamienić info.
        newFilePath = sanitizePath(newFilePath)
    if not str(oldFilePath) == str(newFilePath):
        shutil.move(oldFilePath, newFilePath)
    return newFilePath

#% Remove forbidden characters from the strings that can be used for file names or folders
#function string = sanitizeString(string)
#bannedList = ['[', '^', '\','~','!',' @ ','# ','$','%','^','&','(',')','<','>','{','}',']','*'];
#for i = 1: length(bannedList)
#string = strrep(string, bannedList(i), '');
#end
#end

#function path = sanitizePath(path)
#path = strsplit(path, '/');
#path = cell2mat(path);
#path = strsplit(path, '\');
#path = strjoin(path, '/');
#end

#function path = sanitizeDir(path)
#path = sanitizePath(path);
#path = strcat(path, '/');
#double = strcat('/', '/');
#path = strrep(path, double, '/');
#end

def sanitizeString(string)
    bannedList = ['[', '^', '\','',''#','$','%','^','&','(',')','<','>','{','}',']','*','@','~','!']
    # to: '\' opiera się przecinkom
    for i in range(0, len(bannedList)):
        string = string.replace(bannedList(i),'')
    return string

def sanitizePath(path):
    path = str.split(path, '/')
    path = np.array(path)
    path = path.split('\') #znów ten sam błąd
    path = str(path + '/')
    return path

def sanitizeDir(path):
    path = sanitizePath(path)
    path = str(path + '/')
    double = str('/' + '/')
    path = path.replace(double, '/')
    return path


#% Before renaming checks whether the old and the new path are not the same.
#% Also verifies that new file will not overwrite another if one of the same
#% newFolderPath exists.
#function renameThisFolder(oldFolderPath, newFolderPath)
#    if( ~strcmp(oldFolderPath,newFolderPath) )
#        if ( ~exist(newFolderPath,'dir') )
#            movefile(oldFolderPath,newFolderPath);
#        else
#            [list, listSize] = getFileList(oldFolderPath);
#            for i = 1:listSize
#                moveFile(oldFolderPath,newFolderPath,list(i).name,list(i).name);
#            end
#            rmdir(oldFolderPath)
#        end
#    end
#end


def renameThisFolder(oldFolderPath, newFolderPath):
    if not (str(oldFolderPath) == str(newFolderPath)):
        if not os.path.exists(newFolderPath):
            shutil.move(oldFolderPath,newFolderPath)
        else:
            [list, listSize] = getFileList(oldFolderPath)
            for i in range(1,listSize):
                moveFile(oldFolderPath,newFolderPath,os.path.basename(list(i)),os.path.basename(list(i)))
            os.rmdir(oldFolderPath)


#% Prevents overwrite when moving the file
#function moveFile(oldDir,newDir,oldFileName,newFileName)
#     if( exist(strcat(newDir,'/',newFileName),'file') )
#        newFileName = generateRandomString(20);
#        moveFile(oldDir,newDir,oldFileName,newFileName);
#     else
#        movefile( strcat(oldDir,'/',oldFileName),strcat(newDir,'/',newFileName) );
#     end
#end

def moveFile(oldDir,newDir,oldFileName,newFileName):
    if os.path.exists(str(newDir + '/' + newFileName)):
        newFileName = generateRandomString(20)
        shutil.move(oldDir, newDir, oldFileName, newFileName)
    else:
        shutil.move(str(oldDir + '/' + oldFileName), str(newDir + '/' + newFileName))

#%Generate Random String of chosen max length
#function string = generateRandomString(maxLength)
#    symbols = ['a':'z' 'A':'Z' '0':'9'];
#    stLength = randi(maxLength);
#    nums = randi(numel(symbols),[1 stLength]);
#    string = symbols (nums);
#end

def generateRandomString(maxLength):
    symbols = concatenate((range('a','z'), range('A','Z'), range('0','9'))) #tu mam problem z tym rangem
    stLength = os.urandom(maxLength)
    nums = os.urandom(size(symbols),hstack((0, stLength)))
    string = symbols(nums)
    return string

#% Check if the file is of DICOM format.
#function tf = isDICOM(filename)

#% Open the file -- You can do this in the native endian type
#   fid = fopen(filename, 'r');
#   fseek(fid, 128, 'bof');
#   if (isequal(fread(fid, 4, 'char=>char')', 'DICM'))
#% It has the form of a compliant DICOM file.
#       tf = true;
#   else
#% % It may be a DICOM file without the standard header.
#% fseek(fid, 0, 'bof');
#% tag = fread(fid, 2, 'uint32')';
#% if ((isequal(tag, [8 0]) | | isequal(tag, [134217728 0])) | |...
#% (isequal(tag, [8 4]) | | isequal(tag, [134217728 67108864])))
#% % The first eight bytes look like a typical first tag.
#% tf = true;
#% else
#% It could be a DICOM file, but it's hard to say.
#       tf = false;
#% end
#end
#fclose(fid);
#end

def isDICOM(filename):
    with open(filename, 'r') as fid: #fid = open(filename, 'r')?
        fid.seek(128) # seek(fid, 128, 'bof')? potrzebuję tego 'bof'?
        if fid.read(4) == 'DICM'
            tf = True
        else
            tf = False
        fid.close()
    return tf




