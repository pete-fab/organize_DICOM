%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% title: RenameDicom()
% author: Piotr Faba
% description: Rename DICOM files based on their properties, the files ought
% to be in a subdirectory relative to the position of this script
% version: 2.1
% date: 10/09/2015
%
% Changes at version 2.1:
% - fixed minor spelling issues regarding "ReferringPhysicianName"
%
% Changes at version 2.0:
% - the script comletely rebuilt for full flexibility
% - the number of subfolders is custom
% - all the naming rules can be specified in the main function
% - the mode system was abandoned as not useful
% 
% Changes at version 1.2:
% - added mode=3, for Ola
% - mode=3 adds session folder to mode1 structure
% - mode=3 addes check for the same sessions
% - BUG!! mode=3 puts into one folder studies with the same name
%
% Changes at version 1.1:
% - added flattening of folder hierarchy
% - added renaming of parent fodlers
% - added mode (mode= 0 - flat structure, mode = 1 - subfolder structure,
% mode = 2 - scanner like)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RenameDICOM()
    
    Dir = getScriptDir();
    
    flattenFolderHierarchy(Dir);
    renameChildFolders(Dir,'PatientName;StudyDate',true); 
    % Domgalik template: 'RequestingPhysician'
    
    % enter the subdirectories
    [folderList, listSize] = getFolderList(Dir);
    for i = 1 : listSize(1) %parfor
        counter = 0;
        currentDir = strcat(Dir,'\',folderList(i).name,'\');    
        
        renameFiles(currentDir,'SeriesDescription;PatientName;ReferringPhysicianName','IMA',true); %rename all the files in the diresctory
        % Below are listed file naming templates
        % Siemens Template: 'PatientName;StudyDescription;SeriesNumber;InstanceNumber','IMA'
        % Domagalik Template: 'RequestingPhysician;SeriesDescription','IMA'
        % Example Template: 'SeriesDescription;PatientName;PatientID;RequestedProcedureDescription','DCM'
        
%         counter = addSubFolder(currentDir,counter,'OperatorName','','',true);
        % Domgalik template: Session - the Tag to be determined
        
        counter = addSubFolder(currentDir,counter,'SeriesDescription','SeriesNumber','fieldmap',true);
        % Domagalik template: 'SeriesDescription','SeriesNumber','fieldmap',true
        
        % There can be more subfolders added
%         counter = addSubFolder(currentDir,counter,'RequestingPhysician','',false);
%         counter = addSubFolder(currentDir,counter,'OperatorName','',false);
    end
    
end

% This function creates subfolders according to the specified rules:
% @variables:
% dir - the parent directory containing images
% depth - how deep inside the parent directory are we? How many subfolders
% ruleString - the string containing the rule for creating subfolder name
%   the string consits of dicomInfoTags seperated by semicolon ";"
% differenceRuleString - contains rule constructed as above and containing
%   dicomInfoTags that should be differentiated in folders that would
%   otherwise have the same name
% restrictDiffRuleString - is a variable used when differenceRuleString is
%   not null. It restricts its application to a specified value.
% isCaps - indicates wether to capitalise the names or not (true or false)
function depth = addSubFolder(dir, depth, ruleString, differenceRuleString, restrictDiffRuleString, isCaps)
    [dirList,dirListSize] = getCurrentDirList(dir,depth);

    if( dirListSize == 0 )
        dirList(end+1).path = dir;
        dirListSize = [0 1];
    end
    
    for d = 1 : dirListSize(2)
        currentDir = dirList(d).path;
        [fileList,fileListSize] = getFileList(currentDir);
        
        for f = 1 : fileListSize(1)
            
            %get subfolder folder Name
            currentFilePath = fullfile(currentDir,fileList(f).name);
            info = dicominfo(currentFilePath);
            newDir = createSubFolder(currentDir,info,ruleString,differenceRuleString, restrictDiffRuleString, isCaps);

            %move file to folder
            newFilePath = strcat(newDir,fileList(f).name);
            renameThisFile(currentFilePath,newFilePath);
            
        end
    end
    
    dirSplit = strsplit(dir,'\');
    newDirSplit = strsplit(newDir,'\');
    depth = numel(newDirSplit) - numel(dirSplit);
end

% returns directory of the script
function Dir = getScriptDir()
    fullPath = mfilename('fullpath');
    [Dir, ~,~] = fileparts(fullPath);
end

% returns list of files in the given directory
function [list,listSize] = getFileList(Dir)
    DirResult = dir( Dir );
    list = DirResult(~[DirResult.isdir]); % select files
    listSize = size(list);
end

% returns list of folders in the given diretory
function [list,listSize] = getFolderList(Dir)
    DirResult = dir( Dir );
    list = DirResult([DirResult.isdir]); % select folders
    list(2,:)=[];
    list(1,:)=[];
    listSize = size(list);
end

% renames files in the given directory according to a given rule
% @variables
% currentDir - the directory with the files
% namingRule - a string consisting of semi-colon (;) separated dicomInfoTags
% fileType - string with file type: 'IMA', 'DCM', 'DICOM'
% isCaps - true/false, should the names be capitalised or small letters
function renameFiles(currentDir,namingRule,fileType,isCaps)
    [currentFileList,currentListSize] = getFileList(currentDir);
    % calculate number of digits in number
    numSize = numel(num2str(currentListSize(1))); 

    %format number string
    formatString = strcat('%0',num2str(numSize),'d');
    
    for k = 1 : currentListSize(1)
        
        %read DICOM info
        currentFilePath = fullfile(currentDir,currentFileList(k).name);
        info = dicominfo(currentFilePath);
                
        newFileName = getNewDicomName(info, namingRule, fileType, isCaps, formatString, k-1);
        newFilePath = strcat(currentDir,newFileName);
        
        renameThisFile(currentFilePath,newFilePath);
    end
end

%returns new name for a DICOM file according to given rules
function newFileName = getNewDicomName(dicomInfo, namingRule, fileType, isCaps, formatString, fileNumber)
    
    CoreStr = ruleString2dataString(dicomInfo, namingRule, isCaps);
    newFileName = strcat( CoreStr,...
        '_',sprintf(formatString,fileNumber),... % e.g. 00045
        '.',... 
        fileType... % e.g. .DICOM, .DCM
        );
end

% Create new subdirectory directory based on given rules
% @variables:
% - dir - parent full directory
% - info - DICOM info of the file to be moved to subdirectory
% - ruleString - rule for creating subfolder
% - differenceString - rule for distinguishing similarity between DICOM
% files
function newDir = createSubFolder(dir,info,ruleString,differenceRuleString, restrictDiffRuleString, isCaps)
    isNewDirFound = false;
    k = 0;
    folderName = ruleString2dataString(info, ruleString, isCaps);
    
    %if differenceRuleString is set then the folders will need to change.
    if( ~isempty( differenceRuleString )  && strcmpi(folderName, restrictDiffRuleString) )
        folderName = strcat( folderName, '_0' );
    end
    
    while( ~isNewDirFound )
        
        if( k ~= 0 )
            folderName = adjustFolderName(folderName);
        end
        newDir = strcat(dir,'\',folderName,'\');
        
        if( exist(newDir,'dir') )
            if( isempty(differenceRuleString) )
                return; % if differenceRuleString is empty add to specified directory
                % the differences/similarities between files are ignored
            end
            
            [fileList, fileListSize] = getFileList(newDir);
            if fileListSize(1) == 0
                return; % if empty directory return its name
            end
            % if not empty retrieve information about the first file
            secondFilePath = fullfile(newDir,fileList(1).name);
            info2 = dicominfo(secondFilePath);

            datStr1 = ruleString2dataString(info,differenceRuleString, isCaps);
            datStr2 = ruleString2dataString(info2,differenceRuleString, isCaps);
            if strcmp(datStr1,datStr2) && ~strcmpi(folderName, restrictDiffRuleString)
                return; % if the files inside have the same characteristic return
            end
            
            k = k + 1;
            %  do the while loop again
        else
            isNewDirFound = true;
            mkdir( newDir );
        end
    end
end

% function called whenever differenceRuleString causes conflicts. Then
% folder names get appended numbers to differentiate between them.
function newFolderName = adjustFolderName(folderName)
    splitCell = strsplit(folderName,'_');
    num = str2num( splitCell{end} );
    
    if( isempty(num) || ~isfinite(num) || (num==-999) )
        % not a valid number, append _1 at the end of the new folder name
        newFolderName = strcat(folderName,'_1');
    else
        % number, increment it
        num = num + 1;
        splitCell{end} = num2str(num);
        newFolderName = strjoin(splitCell,'_');
    end
    
end

% Get list of subdirectories of given dir
% if $depth ~= 'a', return all directories
% if $depth is specified, return directories for required child depth.
function [list,listSize] = getCurrentDirList(dir,depth)
    if( ~strcmp(depth,'a') )
        depth = depth - 1;
    end
    list = [];
    [folderList, listSize] = getFolderList(dir);
    for i = 1 : listSize(1) %parfor
        currentDir = strcat(dir,'\',folderList(i).name);
        
        if( strcmp(depth,'a') || depth == 0 )
            list(end+1).path = currentDir;
        end
        
        childList = getCurrentDirList(currentDir,depth);
        list = [list, childList];
    end
    listSize = size(list);
end

% Converts provided rule string into folder compatible form
% @variables:
% - info - uses the provided DICOM file info
% - ruleString - needs to be semi-colon separated for multiple info fields 
% - isCaps - determines whether the letters should upper or lower case
% to be used
function dataString = ruleString2dataString(info,ruleString,isCaps)
    fields = strsplit(ruleString,';');
    fieldsSize = size(fields);
    
    dataString = '';
    for k = 1 : fieldsSize(2)
        if( k > 1)
            dataString = strcat(dataString,'_');
        end
        
        fieldVal = getfield( info,fields{k} );
        if strcmp(fields{k},'PatientName')
            fieldVal = strcat( fieldVal.FamilyName,'_',fieldVal.GivenName );
        elseif( strcmp(fields{k},'ReferringPhysicianName') || strcmp(fields{k},'OperatorName')...
                || strcmp(fields{k},'PerformingPhysicianName') || strcmp(fields{k},'RequestingPhysician') )
            fieldVal = fieldVal.FamilyName;
        end
        fieldValString = parseFieldValue( fieldVal );
        dataString = strcat( dataString, fieldValString);
    end
    
    if( isCaps )
        dataString = upper( dataString );
    else
        dataString = lower( dataString );
    end
end

% The values returned from DICOM info structure not always are suitable for
% naming files or folders. This parser makes them compatible with the
% standard.
function string = parseFieldValue(fieldValueString)
    if( ~ischar(fieldValueString) ) 
        if( isnumeric(fieldValueString) )
            fieldValueString = num2str( fieldValueString );
        else % ~string & ~number
            error( strcat('fieldValueString in parseFieldValue() is not a',...
                'string nor a number. Adjust script to account for this.',...
                'Notify piotr.faba@uj.edu.pl about this error.') );
        end
        
    end
    fieldValueString = strrep(fieldValueString,'^','_');
    fieldValueString = strrep(fieldValueString,'.','_');
    fieldValueString = strrep(fieldValueString,' ','_');
    fieldValueString = strrep(fieldValueString,'-','_'); 
    string = fieldValueString;
end

% renames the folders based on the properties of the first DICOM file
% inside that folder
function renameChildFolders(dirName,ruleString,isCaps)
    %get the directories
    dirResult = dir(dirName);
    allDirs = dirResult([dirResult.isdir]);
    allSubDirs = allDirs(3:end);
    
    %rename them based on their contents
    for i = 1:length(allSubDirs)
        thisDir = allSubDirs(i);
        oldFolderPath = fullfile(dirName,thisDir.name);
        
        % find the file inside the child folder and get its dicom
        % properties
        [allFiles, fileListLength] = getFileList(oldFolderPath);
        if( fileListLength == 0 ) % if empty leave the name as is
            continue;
        end
        
        filePath = fullfile(oldFolderPath,allFiles(1).name);
        info = dicominfo(filePath);
        
        newFolderName = ruleString2dataString(info,ruleString,isCaps);
        newFolderPath = strcat(dirName,'\',newFolderName);
        renameThisFile(oldFolderPath,newFolderPath);    
    end
end

% Convert any folder hierarchy to:
% root
%  - subfolder1
%  - subfolder2
%  - subfolder3
function flattenFolderHierarchy(dirName)
    %get the directories
    dirResult = dir(dirName);
    allDirs = dirResult([dirResult.isdir]);
    allSubDirs = allDirs(3:end);
    
    %rename them based on their contents
    for i = 1:length(allSubDirs)
        thisDir = allSubDirs(i);
        oldName = fullfile(dirName,thisDir.name);
        recursiveMoveFilesToParent(oldName,oldName);
    end
end

%recusrive function to verify the session folder


% recursive function to change move files to parent
% removes the subfolders
% moves all the files into parentDir
% E.g.:
% parent folder:
%   - file1
%   - file2
%   - file3
function recursiveMoveFilesToParent(dirName,parentDir)
    
    % move all the files
    [allFiles, fileListLength] = getFileList(dirName);
    for i = 1 : fileListLength
        thisFile = allFiles(i);
        oldFilePath = fullfile(dirName,thisFile.name);
        newFilePath = strcat(parentDir,'\',thisFile.name);
        renameThisFile(oldFilePath,newFilePath);
    end
    
    %get the directories
    dirResult = dir(dirName);
    allDirs = dirResult([dirResult.isdir]);
    allSubDirs = allDirs(3:end);

    %remove extra folders
    for i = 1:length(allSubDirs)
        thisDir = allSubDirs(i);
        dirPath = fullfile(dirName,thisDir.name);
        recursiveMoveFilesToParent(dirPath,parentDir);
        rmdir(dirPath);
    end
end

% Before renaming checks whether the old and the new path are not the same.
function renameThisFile(oldFilePath, newFilePath)
    if( ~strcmp(oldFilePath,newFilePath) )
        movefile(oldFilePath,newFilePath);
    end
end