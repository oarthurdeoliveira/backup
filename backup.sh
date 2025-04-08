#!/bin/sh

source $HOME/Documentos/GitHub/backup/.env

nome="linux-$(date +%d-%m-%Y)"
log_nome="latest.log"
log_data="log-$(date +%d-%m-%Y).log"

Color_Off='\033[0m'       # Text Reset


Red='\033[0;31m'
Green='\033[0;32m'




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

text_event "Iniciando Backup do $(cat /etc/hostname)"

text_event "Salvando os documentos em um arquivo zip..."

zip -r $main_dir/$nome.zip $backup_dir  >> $main_dir/$log_nome && text_event "Documentos salvos em um zip!" || error_handle "Comando zip falhou" 1 


text_event "Encriptando o arquivo com o recipente $recipiente_gpg..."

gpg -e --output $main_dir/$nome.gpg --recipient $recipiente_gpg $main_dir/$nome.zip >> $main_dir/$log_nome && text_event "Arquivo encripitado com sucesso!" || error_handle "Comando gpg falhou" 1 

text_event "Tentando mover para o $rclone_name"


rclone move $main_dir/$nome.gpg $rclone_name: && text_event "Arquivo enviado no $rclone_name !" && rm $main_dir/$nome.zip || error_handle "Comando rclone falhou" 1

cp $main_dir/$log_nome $main_dir/logs/$log_data

