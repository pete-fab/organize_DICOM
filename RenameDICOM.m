%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% title: RenameDicom()
% author: Piotr Faba
% description: Rename DICOM files based on their properties, the files ought
% to be in a subdirectory relative to the position of this script
% version: 1.1
% date: 02/06/2015
% Changes at version 1.1:
% - added flattening of folder hierarchy
% - added renaming of parent fodlers
% - added mode (mode= 0 - flat structure, mode = 1 - subfolder structure,
% mode = 2 - scanner like)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RenameDICOM(Mode)
    
    if( ~isnumeric(Mode) )
       error('Mode value needs to be numeric'); 
    end
    if( Mode > 2)
        error('This mode is not designed. It is out of range');
    end
    Dir = getScriptDir();
    
    flattenFolderHierarchy(Dir);
    renameChildFolders(Dir);
    
    % enter the subdirectories
    [folderList, listSize] = getFolderList(Dir);
    parfor i = 1 : listSize(1) %parfor
        if( folderList(i).isdir == 1)
            currentDir = strcat(Dir,'\',folderList(i).name,'\');
            currentDir %echo to command line
            
            renameFiles(currentDir, Mode); %rename all the files in the diresctory
        else
            error('This is not a subdirectory');
        end
    end
    
end

function Dir = getScriptDir()
    fullPath = mfilename('fullpath');
    [Dir, ~,~] = fileparts(fullPath);
end

function [list,listSize] = getFileList(Dir)
    DirResult = dir( Dir );
    list = DirResult(~[DirResult.isdir]); % select files
    listSize = size(list);
end

function [list,listSize] = getFolderList(Dir)
    DirResult = dir( Dir );
    list = DirResult([DirResult.isdir]); % select folders
    list(2,:)=[];
    list(1,:)=[];
    listSize = size(list);
end

function renameFiles(currentDir,mode)
    [currentFileList,currentListSize] = getFileList(currentDir);
    % calculate number of digits in number
    numSize = numel(num2str(currentListSize(1))); 

    %format number string
    formatString = strcat('%0',num2str(numSize),'d');
    
    seriesDescription = '';
    isMode2DirDone = 0;
    for k = 1 : currentListSize(1)
        
        %read DICOM info
        currentFilePath = fullfile(currentDir,currentFileList(k).name);
        info = dicominfo(currentFilePath);
        
        % create series subfolder if it's new
        editedDir = currentDir;
        if( mode == 2 )
            editedDir = strcat(editedDir,...
                strrep(info.StudyDescription,'^','_'),...
                '_',info.StudyDate,'_',...
                strrep(info.StudyTime,'.','_'),...
                '\');
            if(isMode2DirDone == 0)
                isMode2DirDone = 1;
                mkdir( editedDir );
            end
        end

        fileDir = editedDir;
        tempSeriesDescription = strcat(info.SeriesDescription,'_',sprintf('%04d',info.SeriesNumber));
        if( ~strcmp(seriesDescription, tempSeriesDescription) && (mode == 1 || mode == 2) )
            seriesDescription = strcat(info.SeriesDescription,'_',sprintf('%04d',info.SeriesNumber));
            fileDir = strcat(editedDir, upper(seriesDescription),'\' );
            mkdir( fileDir );
        elseif(mode == 1 || mode == 2)
            fileDir = strcat(editedDir, upper(seriesDescription),'\' );
        end
        
        
        newFileName = getNewDicomName(info, mode, formatString, k-1);
        
        newFilePath = strcat(fileDir,newFileName);
        renameThisFile(currentFilePath,newFilePath);
    end
end

function newFileName = getNewDicomName(dicomInfo,mode,formatString,fileNumber)
    
    if(mode == 2)
        newFileName = strcat( ...
            upper(dicomInfo.PatientName.FamilyName),... % e.g. Surname capitalised
            '_',upper(dicomInfo.PatientName.GivenName),... % e.g. Name capitalised
            '.',strrep(dicomInfo.StudyDescription,'^','_'),... % e.g. localizer
            '_',sprintf('%04d',dicomInfo.SeriesNumber),... % e.g. Series Number
            '_',sprintf('%04d',dicomInfo.InstanceNumber),... % e.g. Instance Number
            '.IMA'... % e.g. .DICOM, .DCM
        );
    else
        % here you can adjust what the naming will be
        newFileName = strcat( ...
            sprintf(formatString,fileNumber),... % e.g. 00045
            '_',dicomInfo.SeriesDescription,... % e.g. localizer
            '_',dicomInfo.PatientName.FamilyName,... % e.g. Surname
            '_',dicomInfo.PatientName.GivenName,... % e.g. Name
            '_',dicomInfo.PatientID,... % e.g. National ID
            '_',dicomInfo.RequestedProcedureDescription,... % e.g. SONATA
            '.DICOM'... % e.g. .DICOM, .DCM
        );
    end
end

% renames the folders based on the properties of the first DICOM file
% inside that folder
function renameChildFolders(dirName)
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
        newFolderName = strcat( ...
            upper(info.PatientName.FamilyName),... % e.g. upper case SURNAME
            '_',upper(info.PatientName.GivenName),... % e.g. upper case NAME
            '_',info.PatientID... % e.g. National ID
            ); 
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


%% recursive function to change move files to parent
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

function renameThisFile(oldFilePath, newFilePath)
    if( ~strcmp(oldFilePath,newFilePath) )
        movefile(oldFilePath,newFilePath);
    end
end