#!/bin/bash


nome="linux-$(date +%d-%m-%Y)"
log_nome="latest.log"
log_data="log-$(date +%d-%m-%Y).log"

#TODO: Change this to english

rclone_remote=""
file_folder=""
encryption_flag=""

while getopts 'f:r:e:o:' flag; do
  case "${flag}" in
    f) file_folder="${OPTARG}" ;;
    r) rclone_remote="${OPTARG}" ;;
    e) encryption_flag="${OPTARG}" ;;
  esac
done

if   [ -d "${file_folder}" ]; then
  echo "${file_folder} is a directory"
elif [ -f "${file_folder}" ]; then 
  echo "${file_folder} is a file"
else 
  echo "${file_folder} is not valid"
  exit 1
fi

rclone_list="$(rclone listremotes)"



# For the love of god don't forget the : at the end
rclone_remote+=":"

# This is to check if user write an remote that is present on the rclone remotes

if [[ "$rclone_remote" != "" ]] && [[ -z $(rclone listremotes | grep -x $rclone_remote) ]]; then
  echo "Invalid rclone, availables remotes:"
  echo $(rclone listremotes)
  exit 1
fi

echo "OK"

exit 1

function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;  
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}


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

if compgen -G "$main_dir/$log_nome" > /dev/null; then
  truncate -s 0 $main_dir/$log_nome
fi


yes_or_no "Deseja fazer um backup?" && clear || exit 0
  

touch $main_dir/latest.log


# Change to file/folder location
text_event "Starting backup at $(cat /etc/hostname)"

text_event "Saving in a zip file..."

zip -r $main_dir/$nome.zip $backup_dir  >> $main_dir/$log_nome && text_event "Documentos salvos em um zip!" || error_handle "Comando zip falhou" 1 


#text_event "Encriptando o arquivo com o recipente $recipiente_gpg..."

gpg -e --output $main_dir/$nome.gpg --recipient $recipiente_gpg $main_dir/$nome.zip >> $main_dir/$log_nome && text_event "Arquivo encripitado com sucesso!" || error_handle "Comando gpg falhou" 1 

text_event "Tentando mover para o $rclone_name"


rclone move $main_dir/$nome.zip $rclone_name: && text_event "Arquivo enviado no $rclone_name !" && rm $main_dir/$nome.zip || error_handle "Comando rclone falhou" 1

cp $main_dir/$log_nome $main_dir/logs/$log_data

