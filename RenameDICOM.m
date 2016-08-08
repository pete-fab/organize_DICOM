function RenameDICOM(rootDir)
%RENAMEDICOM Rename and organize DICOM files based on their properties
% 
%  RENAMEDICOM(rootDir) renames and organizes all DICOM files recursively inside given path rootDir
%
% Example: 
%  
%  RENAMEDICOM('C:\Root\Directory\With\DICOM\files\in\it')
%
% author: Piotr Faba
% version: 2.9
% date: 28/07/2016
%
% Folder structure can be formed by adding and modifying addSubFolder() functions

    if ~exist(rootDir,'dir')
        error( strcat('Given directory does not exist: ',rootDir,' . Give me something real to work on.') );
    end
    counter = 0;
    rootDir = sanitizeDir(rootDir);
    flattenFolderHierarchy(rootDir);
 
    %% Commonly used DUCOM tags in rules:
    %
    % * RequestingPhysician - sbXX
    % * StudyComments - sX
    % * ReferringPhysicianName - Project Name      

        
    %% Subfolder structure
    %
    % Each subfolder function call creates another subfolder level.
    % counter = addSubFolder(rootDir,counter,'ReferringPhysicianName','','',true); % project name folder
    % counter = addSubFolder(currentDir,counter,'RequestingPhysician','','',false); % Logos setting
    counter = addSubFolder(rootDir,counter,'StudyDate','','',true); % QA setting / KUL setting / LOGOS setting
    counter = addSubFolder(rootDir,counter,'SeriesDescription','SeriesNumber','PatientName',true); % QA setting / KUL setting / LOGOS setting

    
    %% Rename files
    %
    disp(strcat(num2str(counter+3),'. Renaming files'));
%     renameFiles(Dir,'RequestingPhysician;SeriesDescription','IMA',true); %rename all the files in the directory, KUL/LOGOS setting
    renameFiles(rootDir,'StudyDescription;RequestingPhysician','IMA',true); %rename all the files in the directory, QA setting
    % Below are listed file naming templates
    %
    % * Siemens Template: 'PatientName;StudyDescription;SeriesNumber;InstanceNumber','IMA'
    % * Domagalik Template: 'RequestingPhysician;SeriesDescription','IMA'
    % * Example Template: 'SeriesDescription;PatientName;PatientID;RequestedProcedureDescription','DCM'
    
end


function depth = addSubFolder(dir, depth, ruleString, differenceRuleString, commonRuleString, isCaps)
%ADDSUBFOLDER Creates subfolders according to the specified rules
%
% depth = ADDSUBFOLDER(dir, depth, ruleString, differenceRuleString, commonRuleString, isCaps)
% 
% Example:
%
%  counter = ADDSUBFOLDER(rootDir,counter,'SeriesDescription','SeriesNumber','PatientName',true);
%
% Arguments:
% * dir - (string) the parent directory containing images
% * ruleString - (string) the string containing the rule for creating
% subfolder name the string consits of dicomInfoTags seperated by semicolon ";"
% * differenceRuleString - (string) contains rule constructed as above and
% containing dicomInfoTags that should be differentiated in folders that
% would otherwise have the same value resulting in the same value of
% rulreString
% * commonRuleString - (string) is a variable used when
% differenceRuleString is not null. It specifies which images should be put
% together despite the differenceRuleString (they will be distinguished by
% this rule late on) 
% * isCaps - (boolean) indicates wether to capitalise the names or not 
%
% Output:
% * depth - (integer) indicates level of subfolder depth
%
% See also DICOMINFO
    disp(strcat( num2str(depth+2) ,'. Adding subfolders according to the rule: ',ruleString));
    [dirList,dirListSize] = getCurrentDirList(dir,depth);

    if( dirListSize == 0 )
        dirList(end+1).path = dir;
        dirListSize = 1;
    end
    
    CM = []; % create Co Occurance Matrix for difference rules
    
    for d = 1 : dirListSize
        currentDir = dirList(d).path;
        [fileList,fileListSize] = getFileList(currentDir);
        
        for f = 1 : fileListSize
            
            %get subfolder folder Name
            currentFilePath = fullfile(currentDir,fileList(f).name);
            info = dicominfo(currentFilePath);
            [CM, newDir] = createSubFolder(currentDir,info,ruleString,differenceRuleString, commonRuleString, isCaps, CM);

            %move file to folder
            newFilePath = strcat(newDir,fileList(f).name);
            renameThisFile(currentFilePath,newDir,fileList(f).name);
            
        end
    end
    
    dirSplit = strsplit(dir,filesep);
    newDirSplit = strsplit(newDir,filesep);
    depth = numel(newDirSplit) - numel(dirSplit);
end


function Dir = getScriptDir()
%GETSCRIPTDIR Returns directory of the script
%
% Dir = GETSCRIPTDIR() Dir is the current absolute directory path of the
% current script location
%
% See also GETFILELIST, GETFOLDERLIST  
    fullPath = mfilename('fullpath');
    [Dir, ~,~] = fileparts(fullPath);
end


function [list,listSize] = getFileList(Dir)
%GETFILELIST Returns files present in given directory
%
% [list,listSize] = GETFILELIST(Dir) Dir is the absolute directory path.
% list is a struct with file name, date, bytes, isdir and datenum. listSize
% is a number indicating the size
%
% See also GETSCRIPTDIR, GETFOLDERLIST
    DirResult = dir( Dir );
    list = DirResult(~[DirResult.isdir]); % select files
    listSize = size(list,1);
end


function [list,listSize] = getFolderList(Dir)
%GETFOLDERLIST Returns folders present in given directory
%
% [list,listSize] = GETFOLDERLIST(Dir) Dir is the absolute directory path.
% list is a struct with folder name, date, bytes, isdir and datenum.
% listSize is a number indicating the size
%
% See also GETSCRIPTDIR, GETFILELIST

    DirResult = dir( Dir );
    list = DirResult([DirResult.isdir]); % select folders
    list = selectVisibleDirectories(list);
    listSize = size(list);
end


function renameFiles(currentDir,namingRule,fileType,isCaps)
%RENAMEFILES renames files in the given directory according to a given
%rules
%
% RENAMEFILES(currentDir,namingRule,fileType,isCaps)
%
% Example:
% 
%  RENAMEFILES('C:\','StudyDescription;RequestingPhysician','IMA',true);
% 
% Arguments: 
% * currentDir - (string) the absolute directory path with the
% * namingRule - (string) a string consisting of semi-colon (;)
% separated dicomInfoTags 
% * fileType - (string) string with file type: 'IMA', 'DCM', 'DICOM' 
% * isCaps - (boolean) should the names be capitalised or small letters

    [currentFileList,currentListSize] = getFileList(currentDir);
    % calculate number of digits in number
    numSize = numel(num2str(currentListSize)); 

    %format number string
    formatString = strcat('%0',num2str(numSize),'d');
    
    for k = 1 : currentListSize
        
        %read DICOM info
        currentFilePath = fullfile(currentDir,currentFileList(k).name);
        info = dicominfo(currentFilePath);
                
        newFileName = getNewDicomName(info, namingRule, fileType, isCaps, formatString, info.InstanceNumber);
        newFilePath = strcat(currentDir,newFileName);
        
        renameThisFile(currentFilePath,currentDir,newFileName);
    end
    
    [dirList,dirListSize] = getFolderList(currentDir);
    for k = 1 : dirListSize
        childDir = strcat(currentDir,filesep,dirList(k).name,filesep);
        renameFiles(childDir,namingRule,fileType,isCaps)
    end
end


function newFileName = getNewDicomName(dicomInfo, namingRule, fileType, isCaps, formatString, fileNumber)
%GETNEWDICOMNAME returns a new name for a DICOM file according to given rules
%
% newFileName = GETNEWDICOMNAME(dicomInfo, namingRule, fileType, isCaps, formatString, fileNumber)
%
% Arguments:
% * dicomInfo - (struct) contains all DICOM tag information
% * namingRule - (string) rule defining the DICOM tags to be used
% * fileType - (string)  file extenstion 
% * isCaps - (boolean) indicates whthere file name should be capitalised
% * formatString - (string) indicates formatting of file number
% * fileNumber - (integer) appended to file name to keep file distinct from
% other files with the same value for naming rule
%
% See also DICOMINFO
    
    CoreStr = ruleString2dataString(dicomInfo, namingRule, isCaps);
    newFileName = strcat( CoreStr,...
        '_',sprintf(formatString,fileNumber),... % e.g. 00045
        '.',... 
        fileType... % e.g. .DICOM, .DCM
        );
end


function [coOccuranceMatrix, newDir] = createSubFolder(dir,info,ruleString,differenceRuleString,commonRuleString, isCaps, coOccuranceMatrix)
%CREATESUBFOLDER Create new subdirectory directory based on given rules
%
% [coOccuranceMatrix, newDir] = createSubFolder(dir,info,ruleString,...
% differenceRuleString,commonRuleString, isCaps, coOccuranceMatrix)
%
% Arguments:
% * dir - (string) absolute parent directory path
% * info - (struct) DICOM info of the file to be moved to the new subdirectory
% * namingRule - (string) rule defining the DICOM tags to be used
% * differenceString - (string) rule for adding DICOM files into different
% folders despite the same value for the namingRule
% * commonRuleString - (string) rule for preventing the differenceString being
% applied
% * isCaps - (boolean) indicates if name should be capitalised
% * coOccuranceMatrix - (struct) matrix holding the data for applying
% difference and common rules
%
% See also addToCoOccuranceMatrix, 
    isNewDirFound = false;
    k = 0;
    folderName = ruleString2dataString(info, ruleString, isCaps);
    diffStr = ruleString2dataString(info,differenceRuleString, isCaps);
    commonStr = ruleString2dataString(info,commonRuleString, isCaps);
    
    while( ~isNewDirFound )
        
        if( k ~= 0 )
            folderName = adjustFolderName(folderName);
        end
        
        newDir = strcat(dir,filesep,folderName,filesep);
        newDir = sanitizeDir(newDir);
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


function CM = addToCoOccuranceMatrix(CM,differenceRuleValue,commonRuleValue,pathName)
%ADDTOCOOCCURANCEMATRIX Adds the data to Co-Occurance Matrix if it is not already there
%
% CM = ADDTOCOOCCURANCEMATRIX(CM,differenceRuleValue,commonRuleValue,pathName)
%
% Arguments:
% * CM - (struct) the co-occurance matrix,
% * differenceRuleValue - (string) data value
% * commonRuleValue - (string) data value
% * pathName - (string) absolute directory path
%
% Output:
% * CM - (struct) modified co-occurance matrix
%
    if ~isExistInCoOccuranceMatrix(CM,commonRuleValue,pathName)
        CM(end+1).differenceRuleValue = differenceRuleValue;
        CM(end).commonRuleValue = commonRuleValue;
        CM(end).folderName = pathName;
    end
end


function TF = isExistInCoOccuranceMatrix(CM,commonRuleValue, pathName)
%ISEXISTINCOOCCURANCEMATRIX Verifies whether the data exists in Co-Occurance Matrix
% 
% Arguments:
% * CM - (struct) the matrix,
% * commonRuleValue - (string) data value
% * pathName - (string) data value
%
% Output:
% * TF - (boolean) indicates whether given value exists for given path name
    TF = false;
    for i = 1 : size(CM,2)
        if strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
            TF = true;
            break;
        end
    end
end


function TF = isImageAllowedIn(CM,differenceRuleValue,commonRuleValue,pathName)
%ISIMAGEALLOWEDIN Verifies by using Co-Occurance Matrix whether the image
% can be inserted into the given pathName considering the rules
%
% Arguments:
% * CM - (struct) the matrix,
% * differenceRuleValue - (string) data value
% * commonRuleValue - (string) data value
% * pathName - (string) data value
%
% Output:
% * TF - (boolean)
    TF = false;
    for i = 1 : size(CM,2)
        if strcmp(CM(i).differenceRuleValue,differenceRuleValue) && strcmp(CM(i).folderName,pathName) && strcmp(CM(i).commonRuleValue,commonRuleValue)
            TF = true;
            break;
        end
    end
end


function newFolderName = adjustFolderName(folderName)
%ADJUSTFOLDERNAME function called whenever differenceRuleString causes conflicts. Then
% folder names get appended numbers to differentiate between them.
%
% Arguments:
% * folderName - (string) name to be adjusted
%
% Output:
% * newFolderName - (string) adjusted folder name
%
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


function [list,listSize] = getCurrentDirList(dir,depth)
%GETCURRENTDIRLIST - Get list of subdirectories of given dir at specified
% child directory depth
%
%  [list,listSize] = GETCURRENTDIRLIST(dir,depth) if $depth == 'a', return all directories
% else if $depth is specified as number, return directories for required child depth.
%
% Arguments:
% * dir - (string) absolute directory path
% * depth - (number,string) number of depth level or 'a' to inidicate all
%
% Output:
% * list - (struct) 1D list of paths
% * listSize - (number) size of the list
    if( ~strcmp(depth,'a') )
        depth = depth - 1;
    end
    list = [];
    [folderList, listSize] = getFolderList(dir);
    for i = 1 : listSize(1) %parfor
        currentDir = strcat(dir,filesep,folderList(i).name);
        
        if( strcmp(depth,'a') || depth == 0 )
            list(end+1).path = currentDir;
        end
        
        childList = getCurrentDirList(currentDir,depth);
        list = [list, childList];
    end
    listSize = size(list,2);
end


function dataString = ruleString2dataString(info,ruleString,isCaps)
% RULESTRING2DATASTRING Converts provided rule string into string value
% that is compatible for naming files and folders
%
% Arguments:
% * info - (struct) uses the provided info structure provided by DICOMINFO
% * ruleString - (string) needs to be semi-colon separated for multiple info fields 
% * isCaps - (boolean)
%
% Output:
% dataString - (string) formatted string according to rules
%
% See also DICOMINFO
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
    dataString = sanitizeString(dataString);
end


function dataString = applyCaps(dataString, isCaps)
    if( isCaps )
        dataString = upper( dataString );
    else
        dataString = lower( dataString );
    end
end


function result = getField(structure, fieldName)
%GETFIELD Get structure field contents.
%
% F = getfield(structure,'field') returns the contents of the specified
%    field.  This is equivalent to the syntax F = S.field. S must be a
%    1-by-1 structure. Overrides Matlab getfield() function. It adds
%    verification whether the field exists to it.
%
% See also GETFIELD
% 
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


function string = parseFieldValue(fieldValueString)
%PARSEFIELDVALUE make value of field a string suitable for naming files and
%folders. The values returned from DICOM info structure not always are
%suitable for naming files or folders. This parser makes them compatible
%with the standard.
% 
% string = PARSEFIELDVALUE(fieldValueString) 
%
% Example:
%   string = PARSEFIELDVALUE('file#/name')
%
% Arguments:
% * fieldValuestring - (string/number) 
%
% Output:
% * string - (string) corrected string
    if( ~ischar(fieldValueString) ) 
        if( isnumeric(fieldValueString) )
            fieldValueString = num2str( fieldValueString );
        else % ~string & ~number
            error( strcat('fieldValueString in parseFieldValue() is not a',...
                'string nor a number. Adjust script to account for this.',...
                'Notify piotr.faba@uj.edu.pl about this error.') );
        end
        
    end
    string = sanitizeString(fieldValueString);
end


function flattenFolderHierarchy(dirName)
%FLATTENFOLDERHIERARCHY moves all the files to root folder and destroys the
%folders. All non DICOM files will be deleted. DICOM files are renamed to
%their original name identifiers to prevent over writing.
%
% Arguments:
% * dirName - (string) absolute directory path containing a file and folder
% structure to be flattened
    disp('1. Flattening the original directory');
    recursiveMoveFilesToParent(dirName,dirName);
end


function dirResultStruct = selectVisibleDirectories(dirResultStruct)
%SELECTVISIBLEDIRECTORIES Remove dot subdirectories '.' and '..' from list
%of directories
%
% Arguments:
% * dirResultStruct - (struct) containing folder names
%
% Output:
% * dirResultStruct - (struct) modified struct containing folder names

    for i = length(dirResultStruct):-1:1
        if( strcmp(dirResultStruct(i).name,'..') || strcmp(dirResultStruct(i).name,'.') )
            dirResultStruct(i) = [];
        end
    end
    
    if( size(dirResultStruct,2) == 0 )
        dirResultStruct = struct([]);
    end
end


function recursiveMoveFilesToParent(dirName,parentDir)
%RECURSIVEMOVEFILESTOPARENT - moves files in subdirectories at all levels
%to parentDir
%
% E.g. output structure:
% parent folder:
%   - file1
%   - file2
%   - file3
%
% Arguments:
% * dirName - (string) absolute directory path containing files and
% subfolders
% * parentDir - (string) absolute destination directory path 

    % move all the files
    [allFiles, fileListLength] = getFileList(dirName);
    for i = 1 : fileListLength
        thisFile = allFiles(i);
        oldFilePath = fullfile(dirName,thisFile.name);
        if isDICOM(oldFilePath) && ~strcmp(thisFile.name,'DICOMDIR')
            info = dicominfo(oldFilePath);
            renameThisFile(oldFilePath,parentDir,strcat(info.SeriesInstanceUID,'_',num2str(info.InstanceNumber)));
        else
            delete(oldFilePath);
        end
    end
    [allSubDirs, listSize] = getFolderList(dirName);

    %remove extra folders
    for i = 1:listSize
        thisDir = allSubDirs(i);
        dirPath = fullfile(dirName,thisDir.name);
        recursiveMoveFilesToParent(dirPath,parentDir);
        rmdir(dirPath);
    end
end


function renameThisFile(oldFilePath, newFileDir, newFileName)
%RENAMETHISFILE - rename the file.
%
% RENAMETHISFILE(oldFilePath, newFileDir, newFileName) Before renaming
% checks whether the old and the new path are not the same. Also verifies
% that existing file with newFilePath will not be overwritten.
%
% Arguments:
% * oldFilePath - (string) absolute path to file
% * newFileDir - (string) absolute destination directory path
% * newFileName - (string) 

    newFileName = sanitizeString(newFileName);
    newFilePath = strcat(newFileDir,filesep,newFileName);
    newFilePath = sanitizePath(newFilePath);
    if exist(newFilePath,'file')
        info = dicominfo(oldFilePath);
        [~,~,ext] = fileparts(newFilePath); 
        newFilePath = strcat(newFileDir,filesep,info.SOPInstanceUID,ext);
        newFilePath = sanitizePath(newFilePath);
    end
    if( ~strcmp(oldFilePath,newFilePath) )
        movefile(oldFilePath,newFilePath);
    end
end


function string = sanitizeString(string)
%SANITIZESTRING  Remove forbidden characters from the strings that can be
%used for file names or folder names
%
% string = SANITIZESTRING(string)
    bannedList = ['[','^','\','~','!','@','#','$','%','&','(',')','<','>','{','}',']','*'];
    for i = 1 : length(bannedList)
        string = strrep(string, bannedList(i),'_'); 
    end
end


function path = sanitizePath(path)
%SANITIZEPATH Clean path string from wrong folder seperators
%
% path = SANITIZEPATH(path)
%
% Arguments:
% * path - (string) 
%
% Output:
% * path - (string) 
    path = strsplit(path,'/');
    path = cell2mat(path);
    path = strsplit(path,'\');
    path = strjoin(path,filesep);
end


function path = sanitizeDir(path)
%SANITIZEDIR Make sure directory path string terminates with directory
%separator and clean it from double use of separators
%
% path = SANITIZEDIR(path)
%
% Arguments:
% * path - (string) 
%
% Output:
% * path - (string) 
    path = sanitizePath(path);
    path = strcat(path,filesep);
    double = strcat(filesep,filesep);
    path = strrep(path,double,filesep);
end


function tf = isDICOM(filename)
%ISDICOM verify if file is of DICOM type
% 
% tf = isDICOM(filename)
%
% Arguments:
% * filename - (string) absolute path to the file
%
% Output:
% * tf - (boolean)
    
    % Open the file -- You can do this in the native endian type.
    fid = fopen(filename, 'r');
    fseek(fid, 128, 'bof');
    if (isequal(fread(fid, 4, 'char=>char')', 'DICM'))
        % It has the form of a compliant DICOM file.
        tf = true;
    else
        % It could be a DICOM file, but it's hard to say.
        tf = false;
    end
    fclose(fid);
end