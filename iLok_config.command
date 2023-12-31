#!/usr/bin/env bash

#
# esce dallo script
#
function die()
{
    local messages=( "${@}" )
    local message

    for message in "${messages[@]}"
    do
        echo "FATAL | ${message}"
    done
    echo "FATAL | Termino programma"
    echo "FATAL | per consultare log aprire: ${LOGFILE}"
    exit 1
}

#############################################################################
#
# CONFIG percorsi base
#
#############################################################################
#SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)" # percorso script == percorso dati
SCRIPTPATH="$(dirname "${0}")"              # percorso script == percorso dati
DATAPATH="${SCRIPTPATH}"                    # percorso dati == percorso script
CONFIGPATH="${SCRIPTPATH}"                  # percorso dati == percorso script
INCLUDEPATH="${SCRIPTPATH}/.include"        # percorso dati == percorso script
#############################################################################
#
# CONFIG log file
#
#############################################################################
LOGFILENAME=$(basename "${0}" .command).log # <nome script>.log
LOGFILE="${DATAPATH}/${LOGFILENAME}"        # percorso file dati
#
# inizio piping verso LOGFILE
#
{
    #############################################################################
    #
    # CONFIGURAZIONE AMBIENTE
    #
    #############################################################################
    CONFIG="${CONFIGPATH}/.iLok_config"
    . "${CONFIG}" || die "impossibile caricare ${CONFIG}"
    #############################################################################
    #
    # FUNZIONI
    #
    #############################################################################
    INCLUDE="${INCLUDEPATH}/functions.include"
    . "${INCLUDE}" || die "impossibile caricare ${INCLUDE}"
    #############################################################################
    #
    # MAIN
    #
    #############################################################################
    timestamp
    #
    # elabora eventuali opzioni di comando
    #
    if ${ENABLE_OPTIONS}
    then
        get_options ${*}
    fi

    echo "INFO  | CHECK         files..."
    #
    # entrambi i file dati non dovrebbe esistere, pena la sovrascrittura
    # dei dati durante la decrittazione !!!
    # solo il file .enc deve essere presente
    #
    if  [ -f "${DATAFILE}" -a -f "${ENCFILE}" ]
    then
        die "CHECK files FALLITO" "entrambi i file ${DATAFILE} e ${ENCFILE} esistono, impossibile continuare"
    fi
    #
    # il file .enc deve esistere
    #
    if  [ ! -f "${ENCFILE}" ]
    then
        die "CHECK files FALLITO" "il file ${ENCFILE} non esiste, procedere alla prima crittografia"
    fi
    #
    # ultima verifica: il file dati non deve esistere
    #
    if  [ -f "${DATAFILE}" ]
    then
        #
        # il file dati esiste, impossibile continuare
        #
        die "CHECK files FALLITO" "il file ${DATAFILE} esiste, continuando verrebbe sovrascritto"
    fi

    #
    # il file dati non esiste, procedo alla decrittazione
    #
    echo "INFO  | CHECK         files...OK"
    #
    # chiedo password prima di iniziare fino a che non viene inserita
    #
    while ! get_password
    do
        echo "ERROR | e' necessario inserire una password per continuare"
    done

    echo "INFO  | DECRIPTAZIONE ${ENCFILE}..."
    if decrypt
    then
        echo "INFO  | DECRIPTAZIONE ${ENCFILE}...OK"
    else
        #
        # openssl ha restituito un errore
        # cancello file dati errato ed esco
        #
        echo "ERROR | DECRIPTAZIONE ${ENCFILE} FALLITA"
        echo "INFO  | CANCELLAZIONE ${DATAFILE}..."
        if delete_datafile
        then
            echo "INFO  | CANCELLAZIONE ${DATAFILE}...OK"
        else
            #
            # la cancellazione del file dati non
            # e' andata a buon fine
            #
            die "errore cancellando ${DATAFILE} !!!"
    fi
        die "errore decriptando ${ENCFILE}, verificare che la password sia corretta!"
    fi

    #
    # se non ci sono errori il file dati e' presente
    # lo apro con editor di sistema e attendo...
    #
    echo "INFO  | EDIT          ${DATAFILE}..."
    if open -W "${DATAFILE}"
    then
        echo "INFO  | EDIT          ${DATAFILE}...OK"
    else
        #
        # l'editor ha restituito un errore
        # TODO: provare a catturare errore
        #
        die "errore aprendo ${DATAFILE} per editing !!!"
    fi

    #
    # l'editing e' andato a buon fine
    # e l'editor e' stato chiuso
    # procedo alla crittografia del file
    #
    echo "INFO  | CRITTOGRAFIA  ${ENCFILE}..."
    if encrypt
    then
        echo "INFO  | CRITTOGRAFIA  ${ENCFILE}...OK"
    else
        #
        # openssl ha restituito un errore
        #
        die "errore crittografando ${ENCFILE} !!!"
    fi

    #
    # la crittografia e' andata a buon fine
    # procedo con la cancellazione del file dati
    # TODO: aggiungere check esistenza file crittato
    #
    echo "INFO  | CANCELLAZIONE ${DATAFILE}..."
    if delete_datafile
    then
        echo "INFO  | CANCELLAZIONE ${DATAFILE}...OK"
    else
        #
        # la cancellazione del file dati non
        # e' andata a buon fine
        #
        die "errore cancellando ${DATAFILE} !!!"
    fi

    echo "INFO  | FINE"
    echo "INFO  | per consultare log aprire: ${LOGFILE}"
# } 2>&1 | tee "${LOGFILE}"
# 2> >(tee -a $TEMP_ERR) 1> >(tee -a $TEMP_CHK)
# } 2>>"${LOGFILE}" 1> >(tee -a "${LOGFILE}") # stderr to logfile, stdout to terminal and logfile
} 1> >(tee "${LOGFILE}") 2> "${LOGFILE}" # stderr to logfile, stdout to terminal and logfile

rm *.cpgz
