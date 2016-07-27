%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% title: RenameDicom()
% author: Piotr Faba
% description: Rename DICOM files based on their properties, the files ought
% to be in a subdirectory relative to the position of this script
% version: 2.4
% date: 09/11/2015
%
% Changes at version 2.4:
% - a CoOccuranceMatrix was added to account for combination of
% differenceRules and commonRules, it allows to distinguish situations in
% which scans were restarted%
%
% Changes at version 2.3:
% - changed the way script works. It operates by the script given as
% argument
% - it allows to import full PACS folders with all the mess that they come
% with (the script recognises DICOM files) and deletes all the others!
% - the script deals with missing DICOM tags, by substituting them with
% cumpolsory information (PatientName). The script notifies of this event
% by writing message to the console.
% - multiple studies can be converted with this script fairly safely (no
% data should be overwritten or missing), though no guarantees
% 
% Changes at version 2.2:
% - fixed error of removing visible directory when directory was missing 
% '..' or '.' hidden directory
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

function RenameDICOM(Dir)

    if ~exist(Dir,'dir')
        error( strcat('Given directory does not exist: ',Dir,' . Give me something real to work on.') );
    end
    
    flattenFolderHierarchy(Dir);
    
    % Commonly used rules:
    % RequestingPhysician - sbXX
    % StudyComments - sX
    % ReferringPhysicianName - Project Name
   
    % Rule strings can be ; seperated e.g.:
    %renameChildFolders(Dir,'PatientName;StudyDate',true); 
    renameChildFolders(Dir,'ReferringPhysicianName',true);
    
    % enter the subdirectories
    [folderList, listSize] = getFolderList(Dir);
    for i = 1 : listSize(1) %parfor
        counter = 0;
        currentDir = strcat(Dir,'\',folderList(i).name,'\');    
        
        renameFiles(currentDir,'SeriesDescription;PatientName;ReferringPhysicianName','IMA',true); %rename all the files in the directory
        % Below are listed file naming templates
        % Siemens Template: 'PatientName;StudyDescription;SeriesNumber;InstanceNumber','IMA'
        % Domagalik Template: 'RequestingPhysician;SeriesDescription','IMA'
        % Example Template: 'SeriesDescription;PatientName;PatientID;RequestedProcedureDescription','DCM'
        
        % Each subfolder function call creates another subfolder level.
        counter = addSubFolder(currentDir,counter,'SeriesDescription','SeriesNumber','PatientName',true);
        counter = addSubFolder(currentDir,counter,'RequestingPhysician','','',true);
        counter = addSubFolder(currentDir,counter,'StudyComments','','',true);
        % There can be more subfolders added
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
% commonRuleString - is a variable used when differenceRuleString is
%   not null. It specifies which images should be put together despite the
%   differenceRuleString (they will be distinguished by this rule late on)
% isCaps - indicates wether to capitalise the names or not (true or false)
function depth = addSubFolder(dir, depth, ruleString, differenceRuleString, commonRuleString, isCaps)
    [dirList,dirListSize] = getCurrentDirList(dir,depth);

    if( dirListSize == 0 )
        dirList(end+1).path = dir;
        dirListSize = [0 1];
    end
    
    CM = []; % create Co Occurance Matrix for difference rules
    
    for d = 1 : dirListSize(2)
        currentDir = dirList(d).path;
        [fileList,fileListSize] = getFileList(currentDir);
        
        for f = 1 : fileListSize(1)
            
            %get subfolder folder Name
            currentFilePath = fullfile(currentDir,fileList(f).name);
            info = dicominfo(currentFilePath);
            [CM, newDir] = createSubFolder(currentDir,info,ruleString,differenceRuleString, commonRuleString, isCaps, CM);

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
    list = selectVisibleDirectories(list);
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
% - commonRuleString - rule for preventing the differenceString being
% applied
% - isCaps - are the resulting strings to be in capital or small letters 
% - coOccuranceMatrix - matrix holding the data for applying difference and
% common rules
function [coOccuranceMatrix, newDir] = createSubFolder(dir,info,ruleString,differenceRuleString,commonRuleString, isCaps, coOccuranceMatrix)
    isNewDirFound = false;
    k = 0;
    folderName = ruleString2dataString(info, ruleString, isCaps);
    diffStr = ruleString2dataString(info,differenceRuleString, isCaps);
    commonStr = ruleString2dataString(info,commonRuleString, isCaps);
    
    %if differenceRuleString is set then the folders will need to change.
%     if( ~isempty( differenceRuleString ) )% && strcmpi(folderName, restrictDiffRuleString) )
%         folderName = strcat( folderName, '_0' );
%     end
        
    while( ~isNewDirFound )
        
        if( k ~= 0 )
            folderName = adjustFolderName(folderName);
        end
        
        newDir = strcat(dir,'\',folderName,'\');
        coOccuranceMatrix = addToCoOccuranceMatrix(coOccuranceMatrix,diffStr,commonStr,newDir);
        if( exist(newDir,'dir') )
            if( isempty(differenceRuleString) )
                return; % if differenceRuleString is empty add to specified directory
                % the differences/similarities between files are ignored
            end
            
            if isImageAllowedIn(coOccuranceMatrix,diffStr,commonStr,newDir)
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

% Adds the data to Co-Occurance Matrix if it is not already there
% @variables:
% CM - the matrix,
% differenceRuleValue - data value
% commonRuleValue - data value
% pathName - data value
function CM = addToCoOccuranceMatrix(CM,differenceRuleValue,commonRuleValue,pathName)
    if ~isExistInCoOccuranceMatrix(CM,commonRuleValue,pathName)
        CM(end+1).differenceRuleValue = differenceRuleValue;
        CM(end).commonRuleValue = commonRuleValue;
        CM(end).folderName = pathName;
    end
end

% Verifies whether the data exists in Co-Occurance Matrix
% @variables:
% CM - the matrix,
% commonRuleValue - data value
% pathName - data value
function TF = isExistInCoOccuranceMatrix(CM,commonRuleValue, pathName)
    TF = false;
    for i = 1 : size(CM,2)
        if strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
            TF = true;
            break;
        end
    end
end

% Verifies by using Co-Occurance Matrix whether the image can be inserted
% into the given pathName considering the rules
% @variables:
% @variables:
% CM - the matrix,
% differenceRuleValue - data value
% commonRuleValue - data value
% pathName - data value
function TF = isImageAllowedIn(CM,differenceRuleValue,commonRuleValue,pathName)
    TF = false;
    for i = 1 : size(CM,2)
        if strcmp(CM(i).differenceRuleValue,differenceRuleValue) && strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
            TF = true;
            break;
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
    dataString = '';
    
    if strcmp(fields{1},'')
        return;
    end
    fieldsSize = size(fields);
    
    for k = 1 : fieldsSize(2)
        if( k > 1)
            dataString = strcat(dataString,'_');
        end
        
        if isfield( info,fields{k} ) % Check if ths field exists. If it is empty, it may not exist
            fieldVal = getField( info,fields{k} );
        elseif( strcmp(fields{k},'ImageComments') || strcmp(fields{k},'StudyComments') )
            nameString = getField( info, 'PatientName' );
            fieldVal = getField( info, 'StudyDate' );
            disp(strcat('The StudyComment is missing for image taken on ', fieldVal,' for ',nameString));
        elseif( strcmp(fields{k},'RequestingPhysician') )
            dateString = getField( info, 'StudyDate' );
            fieldVal = getField( info, 'PatientName' );
            disp(strcat('The RequestingPhysician is missing for image taken on ', dateString,' for ',fieldVal));
        else
            dateString = getField( info, 'StudyDate' );
            fieldVal = getField( info, 'PatientName' );
            disp(strcat('The',fields{k},' is missing for image taken on ', dateString,' for ',fieldVal));
        end
        fieldValString = parseFieldValue( fieldVal );
        dataString = strcat( dataString, fieldValString);
    end
    
    dataString = applyCaps(dataString, isCaps);
end

function dataString = applyCaps(dataString, isCaps)
    if( isCaps )
        dataString = upper( dataString );
    else
        dataString = lower( dataString );
    end
end

% Overrides Matlab getfield() function. It adds verification whether the
% field exists to it.
function result = getField(structure, fieldName)
    if isfield( structure,fieldName )
        fieldVal = getfield( structure,fieldName );
        if strcmp( fieldName,'PatientName' )
            fieldVal = strcat( getField(fieldVal,'FamilyName') ,'_', getField(fieldVal,'GivenName') );
        elseif( strcmp(fieldName,'ReferringPhysicianName') || strcmp(fieldName,'OperatorName')...
                || strcmp(fieldName,'PerformingPhysicianName') || strcmp(fieldName,'RequestingPhysician') )
            fieldVal = getField(fieldVal,'FamilyName');
        end
        result = fieldVal;
    else
        result = '';
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
    allSubDirs = selectVisibleDirectories( allDirs );
    
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
        
        % the folder could happen to be empty if contained only non-DICOM
        % files or was originally empty. In such case skip moving it.
        if ~isempty(allFiles)
            filePath = fullfile(oldFolderPath,allFiles(1).name);
            info = dicominfo(filePath);

            newFolderName = ruleString2dataString(info,ruleString,isCaps);
            newFolderPath = strcat(dirName,'\',newFolderName);
            renameThisFolder(oldFolderPath,newFolderPath);    
        else
            rmdir(oldFolderPath);
        end
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
    allSubDirs = selectVisibleDirectories( allDirs );
    
    %rename them based on their contents
    for i = 1:length(allSubDirs)
        thisDir = allSubDirs(i);
        oldName = fullfile(dirName,thisDir.name);
        recursiveMoveFilesToParent(oldName,oldName);
    end
end

% Remove dot subdirectories '.' and '..'
function dirResultStruct = selectVisibleDirectories(dirResultStruct)
    for i = length(dirResultStruct):-1:1
        if( strcmp(dirResultStruct(i).name,'..') || strcmp(dirResultStruct(i).name,'.') )
            dirResultStruct(i) = [];
        end
    end
    
    if( size(dirResultStruct,2) == 0 )
        dirResultStruct = struct([]);
    end
end


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
        if isDICOM(oldFilePath) && ~strcmp(thisFile.name,'DICOMDIR')
            newFilePath = strcat(parentDir,'\',thisFile.name);
            renameThisFile(oldFilePath,newFilePath);
        else
            delete(oldFilePath);
        end
    end
    fileListLength = size(allFiles);
    
    %get the directories
    dirResult = dir(dirName);
    allDirs = dirResult([dirResult.isdir]);
    allSubDirs = selectVisibleDirectories( allDirs );

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

% Before renaming checks whether the old and the new path are not the same.
function renameThisFolder(oldFolderPath, newFolderPath)
    if( ~strcmp(oldFolderPath,newFolderPath) )
        if ( ~exist(newFolderPath,'dir') )
            movefile(oldFolderPath,newFolderPath);
        else
            [list, listSize] = getFileList(oldFolderPath);
            for i = 1:listSize
                moveFile(oldFolderPath,newFolderPath,list(i).name,list(i).name);
            end
            rmdir(oldFolderPath)
        end
    end
end

% Prevents overwrite when moving the file
function moveFile(oldDir,newDir,oldFileName,newFileName)
     if( exist(strcat(newDir,'\',newFileName),'file') )
        newFileName = generateRandomString(20);
        moveFile(oldDir,newDir,oldFileName,newFileName);
     else
        movefile( strcat(oldDir,'\',oldFileName),strcat(newDir,'\',newFileName) );
     end
end

%Generate Random String of chosen max length
function string = generateRandomString(maxLength)
    symbols = ['a':'z' 'A':'Z' '0':'9'];
    stLength = randi(maxLength);
    nums = randi(numel(symbols),[1 stLength]);
    string = symbols (nums);
end

% Check if the file is of DICOM format.
function tf = isDICOM(filename)

    % Open the file -- You can do this in the native endian type.
    fid = fopen(filename, 'r');

    fseek(fid, 128, 'bof');

    if (isequal(fread(fid, 4, 'char=>char')', 'DICM'))

       % It has the form of a compliant DICOM file.
       tf = true;

    else

%        % It may be a DICOM file without the standard header.
%        fseek(fid, 0, 'bof');
% 
%        tag = fread(fid, 2, 'uint32')';
% 
%        if ((isequal(tag, [8 0]) || isequal(tag, [134217728 0])) || ...
%            (isequal(tag, [8 4]) || isequal(tag, [134217728 67108864])))
% 
%          % The first eight bytes look like a typical first tag.
%          tf = true;
% 
%        else

         % It could be a DICOM file, but it's hard to say.
         tf = false;

%        end

    end

    fclose(fid);
end