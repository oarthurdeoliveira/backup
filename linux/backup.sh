#!/bin/bash

# Get the path of the script
temp=$( realpath "$0"  )
main_path="$(dirname $temp)"

nome="linux-$(date +%d-%m-%Y)"
log_latest="latest.log"
log_data="log-$(date +%d-%m-%Y).log"


rclone_remote=""
file_folder=""
encryption_flag=""
encryption_file_name=""
helper_flag=""
file_type=""

# Flags

while getopts 'f:r:e:o:h' flag; do
  case "${flag}" in
    f) file_folder="${OPTARG}" ;;
    r) rclone_remote="${OPTARG}" ;;
    e) encryption_file_name="${OPTARG}" & encryption_flag="True" ;;
    h) helper_flag="True" ;;
  esac
done

# Checks before running the code

# TODO: check for rclone and zip commands

if [ -d "${main_path}/logs" ]; then
  echo "folder logs exists"
else
  echo "folder dont exist"
  mkdir $main_path/logs
  #log that folder logs was created
fi

if [[ "${helper_flag}" == "True" ]]; then
  echo "-f [path to folder or file] (Required)"
  echo "-r [rclone remote path] (Required)"
  echo "-e [gpg recipient] (Optional)"
  echo "-h helper flag"
  exit 0
fi

if [[ "${file_folder}" == "" ]]; then
  echo "Folder or file path not defined"
  echo "Please use the flag -f [path]"
  exit 1   
elif [ -d "${file_folder}" ]; then
  file_type="folder"
elif [ -f "${file_folder}" ]; then 
  echo "${file_folder} is a file"
  file_type="file"
else 
  echo "Invalid Path, check if file or folder exists."
  exit 1
fi

#test_rclone=""
#rclone_list="$(rclone about $rclone_remote)"

#TODO: Check if the rclone remote given by the user is valid
# Removed the old one, because it was giving errors when user would type the folder location on the rclone (like remote:/path)

if [[ "$rclone_remote" == "" ]]; then
  echo "Default rclone remote not found, please assign a remote using the flag -r [remote]"
  exit 1
fi

#function yes_or_no {
#    while true; do
#        read -p "$* [y/n]: " yn
#        case $yn in
#            [Yy]*) return 0  ;;  
#            [Nn]*) echo "Aborted" ; return  1 ;;
#        esac
#    done
#}


text_event () {
  text=$1

  echo "$text" 
}

error_handle () {
  text=$1
  number=$2

  echo "$text" 

  exit $number
}

# Clear the file

if compgen -G "$main_path/$log_latest" > /dev/null; then
  truncate -s 0 $main_path/$log_latest
fi
  
touch $main_path/latest.log


# Change to file/folder location
text_event "Starting backup at $file_folder"

text_event "Saving in a zip file..."

# Make 

zip -r $main_path/$nome.zip $file_folder >> $main_path/$log_latest && text_event "Files saved on a zip file!" || error_handle "Zip command failed" 1 

#text_event "Encriptando o arquivo com o recipente $recipiente_gpg..."
if [[ "${encryption_flag}" == "True" ]]; then
  gpg -e --output $main_path/$nome.gpg --recipient $recipiente_gpg $main_path/$nome.zip >> $main_path/$log_latest && text_event "File encrypted successfully" || error_handle "Gpg command failed" 1 
fi

text_event "Moving file to $rclone_remote"

rclone move  --log-file=$main_path/$log_latest $main_path/$nome.zip $rclone_remote && text_event "File send to $rclone_remote"  || error_handle "Rclone command failed" 1

cp $main_path/$log_latest $main_path/logs/$log_data

