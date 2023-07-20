#!/usr/bin/env bash

#############################################################################
#
# CONFIG
#
#############################################################################
SCRIPTPATH="$(dirname "${0}")"          # percorso script == percorso dati
DATAPATH="$(dirname "${0}")"            # percorso dati == percorso script

LOGFILENAME=$(basename "${0}" .command).log # <nome script>.log
DATAFILENAME=iLok.xlsx                  # nome file dati
ENCFILENAME=iLok.auth                   # nome file criptato

LOGFILE="${DATAPATH}/${LOGFILENAME}"    # percorso file dati
DATAFILE="${DATAPATH}/${DATAFILENAME}"  # percorso file dati
ENCFILE="${DATAPATH}/${ENCFILENAME}"    # percorso file criptato
#############################################################################
#
# FUNZIONI
#
#############################################################################
#
# ritorna timestamp corrente
#
function timestamp()
{
    echo "$(date '+%Y/%m/%d-%H:%M:%S')"
}
#
# esce dallo script
#
function die()
{
    local message
    message="${1}"
    echo -e "\nFATAL | ${message}"
    echo "Termino programma"
    echo "per consultare log aprire: ${LOGFILE}"
    exit 1
}
#
# cancella file dati in chiaro
#
function delete_datafile()
{
    echo -n "CANCELLO ${DATAFILE}..."
    rm "${DATAFILE}"
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
#
function get_password()
{
    read -sp 'PASSWORD: ' ENCPASS
    echo ""
    [ "${ENCPASS}" == "" ] && return 1 || return 0
}
#############################################################################
#
# MAIN
#
#############################################################################
{
    timestamp
    #
    # chiedo password prima di iniziare
    #
    get_password || die "e' necessario inserire una password per continuare"
    #
    # entrambi i file dati non dovrebbe esistere, pena la sovrascrittura
    # dei dati durante la decrittazione !!!
    # solo il file .enc deve essere presente
    #
    if  [ -f "${DATAFILE}" -a -f "${ENCFILE}" ]
    then
        die "entrambi i file ${DATAFILE} e ${ENCFILE} esistono, impossibile continuare"
    fi
    #
    # il file .enc deve esistere
    #
    if  [ ! -f "${ENCFILE}" ]
    then
        die "il file ${ENCFILE} non esiste, procedere alla prima crittografia"
    fi
    #
    # ultima verifica: il file dati non deve esistere
    #
    if  [ -f "${DATAFILE}" ]
    then
        #
        # il file dati esiste, impossibile continuare
        #
        die "il file ${DATAFILE} esiste, continuando verrebbe sovrascritto"
    else
        #
        # il file dati non esiste, procedo alla decrittazione
        #
        echo -n "DECRITTO ${ENCFILE}..."
        decrypt && {
            echo "Ok"
        } || {
            #
            # openssl ha restituito un errore
            # cancello file dati errato ed esco
            #
            echo ""
            delete_datafile            
            die "errore decriptando ${ENCFILE}, verificare che la password sia corretta!"
        }
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
    echo "per consultare log aprire: ${LOGFILE}"
} 2>&1 | tee "${LOGFILE}"
