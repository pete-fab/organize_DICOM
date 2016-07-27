%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% title: RenameDicom()
% author: Piotr Faba
% description: Rename DICOM files based on their properties, the files ought
% to be in a subdirectory relative to the position of this script
% version: 1.0
% date: 31/05/2015
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RenameDICOM()
    clear all;
    Dir = getScriptDir();
    
    [fileList, listSize] = getfileList(Dir);

    % enter the subdirectories
    parfor i = 1 : listSize(1)
        if( fileList(i).isdir == 1)
            currentDir = strcat(Dir,'\',fileList(i).name,'\');
            currentDir %echo to command line
            renameFiles(currentDir); %rename all the files in the diresctory, avoid subdirectories
        else
            error('This is not a subdirectory');
        end
    end
end

function Dir = getScriptDir()
    fullPath = mfilename('fullpath');
    [Dir, ~,~] = fileparts(fullPath);
end

function [fileList,listSize] = getfileList(Dir)
    fileList = dir( Dir );
    listSize = size(fileList);

    % remove unnecesarry elements in list
    for i = listSize(1) : -1 : 1
        if( strcmp(fileList(i).name,'.') || strcmp(fileList(i).name,'..') )
            fileList(i,:) = [];
        elseif( fileList(i).isdir == 0 )
            fileList(i,:) = [];
        end
    end
    listSize = size(fileList);
end

function renameFiles(currentDir)
    currentFileList = dir( currentDir );
    currentListSize = size(currentFileList);
    
    % calculate number of digits in number
    numSize = numel(num2str(currentListSize(1))); 

    %format number string
    formatString = strcat('%0',num2str(numSize),'d\n');
    l = 1;
    for k = 1 : currentListSize(1)
        if(currentFileList(k).isdir == 1) % avoid subdirectories
            l = l + 1;
            continue;
        end
        currentFilePath = strcat(currentDir,'\',currentFileList(k).name);
        info = dicominfo(currentFilePath);
        newFileName = strcat( ...
            sprintf(formatString,k-l),... % e.g. 00045
            '_',info.SeriesDescription,... % e.g. localizer
            '_',info.PatientName.FamilyName,... % e.g. Surname
            '_',info.PatientName.GivenName,... % e.g. Name
            '_',info.PatientID,... % e.g. National ID
            '_',info.RequestedProcedureDescription,... % e.g. SONATA
            '.DICOM'... % e.g. .DICOM, .DCM
            ); 
        newFilePath = strcat(currentDir,'\',newFileName);
        movefile(currentFilePath,newFilePath);
    end
end

