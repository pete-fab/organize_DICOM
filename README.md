# organize_DICOM
This repository contains script(s) that can be used for custom organizing DICOM files based their attributes

scrupt title: renameDicom()
author: Piotr Faba
 description: Rename DICOM files based on their properties, the files ought
 to be in a subdirectory relative to the position of this script
 version: 2.9
 date: 28/07/2016

 Example use: RenameDicom('C:\Root\Directory\With\DICOM\files')
 Folder structure can be formed by adding addSubFolder functions()

Changes at version 2.9
 - unified behaviour - no need renameChildFolders(); now all data is
 initially moved to the rootFolder and then the structure is built by
 adding addSubFolder() functions
 - commenting is redone

Changes at version 2.8
 - fixed issue of files over writing when processing multiple subjects;
 files are being renamed to unique SOPInstanceUID and renamed to requested
 name after creating subfolders
 - ordering of files is fixed according to instance numbering in DICOM

Changes at version 2.7
 - added function sanitizeString(); it is used on strings used for file
 names and folder names to remove illegal characters from them, that would
 cause error in file renaming or folder creation

Changes at version 2.6
 - if renameChildFolders() is DICOM info for renaming folders then
 original name will be preserved

Changes at version 2.5:
 - fixed major error that script was overwriting DICOM files in
 flattenFolderHierarchy()

Changes at version 2.4:
 - a CoOccuranceMatrix was added to account for combination of
 differenceRules and commonRules, it allows to distinguish situations in
 which scans were restarted

Changes at version 2.3:
 - changed the way script works. It operates by the script given as
 argument
 - it allows to import full PACS folders with all the mess that they come
 with (the script recognises DICOM files) and deletes all the others!
 - the script deals with missing DICOM tags, by substituting them with
 cumpolsory information (PatientName). The script notifies of this event
 by writing message to the console.
 - multiple studies can be converted with this script fairly safely (no
 data should be overwritten or missing), though no guarantees

Changes at version 2.2:
 - fixed error of removing visible directory when directory was missing
 '..' or '.' hidden directory

Changes at version 2.1:
 - fixed minor spelling issues regarding "ReferringPhysicianName"

Changes at version 2.0:
 - the script comletely rebuilt for full flexibility
 - the number of subfolders is custom
 - all the naming rules can be specified in the main function
 - the mode system was abandoned as not useful

Changes at version 1.2:
 - added mode=3, for Ola
 - mode=3 adds session folder to mode1 structure
 - mode=3 addes check for the same sessions
 - BUG!! mode=3 puts into one folder studies with the same name

Changes at version 1.1:
 - added flattening of folder hierarchy
 - added renaming of parent fodlers
 - added mode (mode= 0 - flat structure, mode = 1 - subfolder structure,
 mode = 2 - scanner like)


