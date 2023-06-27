#!/usr/bin/env bash

DATAPATH="$(dirname $0)"                # percorso dati == percorso script

LOGFILENAME=$(basename $0 .command).log # <nome script>.log
DATAFILENAME=secret.txt                 # nome file dati
ENCFILENAME=secret.enc                  # nome file criptato

LOGFILE="${DATAPATH}/${LOGFILENAME}"    # percorso file dati
DATAFILE="${DATAPATH}/${DATAFILENAME}"  # percorso file dati
ENCFILE="${DATAPATH}/${ENCFILENAME}"    # percorso file criptato

#
#
#
function die()
{
    local message
    message="${1}"
    echo -e "\nFATAL | ${message}"
    echo "Termino programma"
    exit 1
}
#
#
#
function delete_datafile()
{
    echo -n "CANCELLO ${DATAFILE}..."
    rm ${DATAFILE}
}
#
# decripta il file
#
function decrypt()
{
    local errorcode
    openssl enc -d -aes-256-cbc -in "${ENCFILE}" -out "${DATAFILE}" -k "${ENCPASS}" 2>> "${LOGFILE}"
    errorcode=$?
    echo -e "\nencrypt error code: ${errorcode}" >> "${LOGFILE}"
    return ${errorcode}
}
#
# cripta il file
#
function encrypt()
{
    local errorcode
    openssl enc -aes-256-cbc -out "${ENCFILE}" -in "${DATAFILE}" -k "${ENCPASS}" 2>> "${LOGFILE}"
    errorcode=$?
    echo -e "\nencrypt error code: ${errorcode}" >> "${LOGFILE}"
    return ${errorcode}
}
#
# chiede password: se vuota esce male
# TODO: separare die()
#
function get_password()
{
    read -sp 'PASSWORD: ' ENCPASS
    echo ""
    [ "${ENCPASS}" == "" ] && return 1 || return 0
}
#
# TODO: creare cleanup
#
{
    #
    # chiedo password prima di iniziare
    #
    get_password || die "e' necessario inserire una password per continuare"
    #
    # TODO il file dati non dovrebbe esistere, pena la sovrascrittura
    # dei dati durante la decrittazione
    #
    if  [ ! -f ${DATAFILE} ]
    then
        #
        # il file dati non esiste, procedo alla decrittazione
        #
        echo -n "DECRITTO ${ENCFILE}..."
        decrypt && {
            echo "Ok"
        } || {
            #
            # openssl ha restituito un errore
            #
            echo ""
            delete_datafile            
            die "errore decriptando ${ENCFILE} !!!"
        }
    else
        #
        # il file dati esiste, impossibile continuare
        #
        die "il file ${DATAFILE} esiste"
    fi

    #
    # se non ci sono errori il file dati e' presente
    # lo apro con editor di sistema e attendo...
    #
    echo -n "EDIT ${DATAFILE}..."
    open -W "${DATAFILE}" && {
        echo "Ok"
    } || {
        #
        # l'editor ha resistuito un errore
        # TODO: provare a catturare errore
        #
        die "errore aprendo ${DATAFILE} per editing !!!"
    }

    #
    # l'editing e' andato a buon fine
    # e l'editor e' stato chiuso
    # procedo alla crittografia del file
    #
    echo -n "CRIPTO ${ENCFILE}..."
    encrypt && {
            echo "Ok"
    } || {
        #
        # openssl ha restituito un errore
        #
        die "errore decriptando ${ENCFILE} !!!"
    }

    #
    # la crittografia e' andata a buon fine
    # procedo con la cancellazione del file dati
    # TODO: aggiungere check esistenza file crittato
    #
    delete_datafile && {
        echo "Ok"
    } || {
        #
        # la cancellazione del file dati non
        # e' andata a buon fine
        #
        die "errore cancellando ${DATAFILE} !!!"
    }

    echo FINE
} 2>&1 | tee "${LOGFILE}"

