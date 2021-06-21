#!/bin/bash

set -e


for i in "$@"
do
case $i in
    --borg_action=*) # borg_action = create or init or prune or check
    BORG_ACTION="${i#*=}"
    shift # 
    ;; 
    --borg_remote_repo_url=*) # remote_repo url ssh://borg@borg.linux2be.com:24
    BORG_REPO_REMOTE_URL="${i#*=}"
    shift #
    ;;  
    --borg_repo_name=*) # action = create or init or prune or check
    BORG_REPO_NAME="${i#*=}"
    shift #
    ;;
    --backup_dirs=*) # backup dirs with spaces /tmp /etc
    BACKUP_DIRS="${i#*=}"
    shift # 
    ;;
    --backup_exclude=*) # filename to exclude
    BACKUP_EXCLUDE="${i#*=}"
    shift # 
    ;;
    --borg_arhive=*) # remote archive name. Example data,databases
    BORG_ARCHIVE="${i#*=}"
    shift # 
    ;;
    --borg_prune=*) # if 1 then prune,else skip
    BORG_PRUNE="${i#*=}"
    shift # 
    ;;
    --borg_prune_options=*) # --keep-daily=7 --keep-weekly=4 --keep-monthly=24 --prefix='data-'
    BORG_PRUNE_OPTIONS="${i#*=}"
    shift # 
    ;;
    --borg_arhive_postfix=*) # Example current date via variable. $(date +%Y_%m_%d__%H_%M_%S)
    BORG_ARCHIVE_POSTFIX="${i#*=}"
    shift # 
    ;; 
    *)
          # unknown option
    ;;
esac
done

#VARS
BACKUP_EXCLUDE_DEFAULT="/borg_client/borg_exclude_default.list"
BORG_PRUNE_OPTIONS_DEFAULT="--keep-daily=7 --keep-weekly=4 --keep-monthly=24"
error_message="error"

if [[ -z "${BORG_ACTION}" ]];then
   echo "${error_message} --borg_action empty."
   exit 1
fi

precheck(){
    echo "-----------------------------"
    echo "Run borg with ${BORG_ACTION}"
    echo "-----------------------------"
    sleep 5;
if [[ -z "${BORG_ARCHIVE_POSTFIX}" ]];then
    BORG_ARCHIVE_POSTFIX=$(date +%Y_%m_%d__%H_%M_%S)
fi
}

error_handler(){
    echo "$1"
    exit 1
}

borg_prepare(){
    echo "Run ${FUNCNAME[ 0 ]}"
    borg_list || borg_init
}

borg_precheck(){
    echo "Run ${FUNCNAME[ 0 ]}"
    borg_list || (error_handler "Error in function ${FUNCNAME[ 0 ]}")
}
borg_init(){
    echo "Run ${FUNCNAME[ 0 ]}"
    echo "Run borg_init. borg init --encryption=none \"${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}\""
    borg init --encryption=none "${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}"
}

borg_create(){
    echo "Run ${FUNCNAME[ 0 ]}"
    #borg_precheck
    echo "Run borg_create. borg create --stats --list --progress ${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}::\"${BORG_ARCHIVE}\" ${BACKUP_DIRS}"
    borg create --stats --list --progress --exclude-from ${BACKUP_EXCLUDE:-${BACKUP_EXCLUDE_DEFAULT}} ${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}::${BORG_ARCHIVE}-${BORG_ARCHIVE_POSTFIX} ${BACKUP_DIRS}
}

borg_prune(){
    echo "Run ${FUNCNAME[ 0 ]}"

    if [[ "${BORG_PRUNE}" == "1" ]];then
        echo "Run borg_prune. borg prune -v --list  --stats ${BORG_PRUNE_OPTIONS:-${BORG_PRUNE_OPTIONS_DEFAULT}} ${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}"
        borg prune -v --list  --stats ${BORG_PRUNE_OPTIONS:-${BORG_PRUNE_OPTIONS_DEFAULT}} "${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}"
    else
        echo "Borg prune skip.Env variable BORG_PRUNE not equal 1"
    fi
}


borg_list(){
    echo "Run ${FUNCNAME[ 0 ]}"
    echo "Run borg list \"${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}\""
    borg list "${BORG_REPO_REMOTE_URL}/./${BORG_REPO_NAME}"
}

borg_check(){
    echo "Run ${FUNCNAME[ 0 ]}"
    sleep 1;
    echo "Exec borg check -v --show-rc --save-space  --prefix=${BORG_ARCHIVE}-"
    borg check -v --show-rc --save-space  --prefix="${BORG_ARCHIVE}-" 

#data-2021_06_21__04_59_39
}

borg_default(){
    echo "Run ${FUNCNAME[ 0 ]}"
    borg_create || error_handler
    borg_prune
    borg_list
}

main(){
    precheck
    
    #borg_precheck
    if [[ "${BORG_ACTION}" == "init" ]];then
        borg_prepare
        borg_init
    fi
    if [[ "${BORG_ACTION}" == "create" ]];then
        borg_prepare
        borg_create || error_handler
        borg_list
    fi
    if [[ "${BORG_ACTION}" == "prune" ]];then
        borg_prune || error_handler
        borg_list
    fi
    if [[ "${BORG_ACTION}" == "check" ]];then
        borg_check || error_handler
        borg_list
    fi
    if [[ "${BORG_ACTION}" == "list" ]];then
        borg_list || error_handler
    fi
    if [[ "${BORG_ACTION}" == "" ]];then
        echo ""
        borg_default || error_handler
    fi
}

main