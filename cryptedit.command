#!/usr/bin/env bash

DATAPATH="$(dirname $0)"                # percorso dati == percorso script

LOGFILENAME=$(basename $0 .command).log # <nome script>.log
DATAFILENAME=secret.txt                 # nome file dati
ENCFILENAME=secret.enc                  # nome file criptato

LOGFILE="${DATAPATH}/${LOGFILENAME}"    # percorso file dati
DATAFILE="${DATAPATH}/${DATAFILENAME}"  # percorso file dati
ENCFILE="${DATAPATH}/${ENCFILENAME}"    # percorso file criptato


#
# cripta il file
#
function encrypt()
{
    local errorcode
    openssl enc -d -aes-256-cbc -in "${ENCFILE}" -out "${DATAFILE}" -k "${ENCPASS}" 2>> "${LOGFILE}"
    errorcode=$?
    echo -e "\nencrypt error code: ${errorcode}"  2>> "${LOGFILE}"
    return ${errorcode}
}
#
# decripta il file
#
function decrypt()
{
    local errorcode
    openssl enc -aes-256-cbc -out "${ENCFILE}" -in "${DATAFILE}" -k "${ENCPASS}" 2>> "${LOGFILE}"
    errorcode=$?
    echo -e "\nencrypt error code: ${errorcode}"  2>> "${LOGFILE}"
    return ${errorcode}
}
#
# chiede password: se vuota esce male
#
function password_or_die()
{
    read -sp 'PASSWORD: ' ENCPASS
    [ "${ENCPASS}" == "" ] && {
        echo "FATAL | per procedere e' necessario inserire una password"
        exit 1
    }
}
#
# TODO: creare cleanup
#
{
    #
    # chiedo password prima di iniziare
    #
    password_or_die
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
        encrypt && {
            echo "Ok"
        } || {
            #
            # openssl ha restituito un errore
            #
            echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
            echo "Termino programma"
            exit 2
        }
    else
        #
        # il file dati esiste, impossibile continuare
        #
        echo "ERRORE | il file ${DATAFILE} esiste"
        exit 3
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
        echo "ERRORE aprendo ${DATAFILE} per editing !!!"
        exit 4
    }

    #
    # l'editing e' andato a buon fine
    # e l'editor e' stato chiuso
    # procedo alla crittografia del file
    #
    echo -n "CRITTO ${ENCFILE}..."
    decrypt && {
            echo "Ok"
    } || {
        #
        # openssl ha restituito un errore
        #
        echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
        echo "Termino programma"
        exit 5
    }

    #
    # la crittografia e' andata a buon fine
    # procedo con la cancellazione del file dati
    # TODO: aggiungere check esistenza file crittato
    #
    echo -n "CANCELLO ${DATAFILE}..."
    rm ${DATAFILE} && {
        echo "Ok"
    } || {
        #
        # la cancellazione del file dati non
        # e' andata a buon fineß
        #
        echo "ERRORE cancellando ${DATAFILE} !!!"
        exit 6
    }

    echo FINE
} 2>&1 | tee "${LOGFILE}"

