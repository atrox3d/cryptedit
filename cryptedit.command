#!/usr/bin/env bash

#############################################################################
#
# CONFIG
#
#############################################################################
#
# percorsi base
#
SCRIPTPATH="$(dirname $0)"              # percorso script == percorso dati
DATAPATH="$(dirname $0)"                # percorso dati == percorso script
#
# nomi files
#
LOGFILENAME=$(basename $0 .command).log # <nome script>.log
DATAFILENAME=secret.txt                 # nome file dati
ENCFILENAME=secret.enc                  # nome file criptato
#
# percorsi di lavoro
#
LOGFILE="${DATAPATH}/${LOGFILENAME}"    # percorso file dati
DATAFILE="${DATAPATH}/${DATAFILENAME}"  # percorso file dati
ENCFILE="${DATAPATH}/${ENCFILENAME}"    # percorso file criptato
#
# opzioni, nel caso si vogliano implementare
#
ENABLE_OPTIONS=false                    # TODO
ENABLE_HISTORY=false                    # TODO
ENABLE_MODULES=false                    # TODO
#############################################################################
#
# FUNZIONI
#
#############################################################################
#
# help dello script
#
function get_help()
{
    echo "SINTASSI | ${0} -[ionh]"
    echo "SINTASSI | -h questo help"
    echo "SINTASSI | -i input file"
    echo "SINTASSI | -o output file"
    echo "SINTASSI | -n nuova installazione"

}
#
# gestisce le opzioni di linea di comando
#
function get_options()
{
    while getopts ":i:o:nh" opt
    do
        case "${opt}" in
            i)
                DATAFILE="${DATAPATH}/${OPTARG}"  # percorso file dati
                echo "DATAFILE=${DATAFILE}"
            ;;
            o)
                ENCFILE="${DATAPATH}/${OPTARG}"  # percorso file criptato
                echo "ENCFILE=${ENCFILE}"
            ;;
            n)
                NEWINSTALL=true                  # TODO: gestire nuova installazione
                echo "NEWINSTALL=${NEWINSTALL}"
            ;;
            h)
                get_help                         # mostra aiuto ed esce
                exit
            ;;
            \?)
                # errore opzione non prevista
                get_help
                die "opzione non riconosciuta: -${opt}"
            ;;
            :)
                # errore parametro mancante
                get_help
                die "l'opzione -${OPTARG} richiede un parametro"
            ;;
        esac
    done
    shift "$((OPTIND-1))"
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
    # elabora eventuali opzioni di comando
    #
    if $ENABLE_OPTIONS
    then
        get_options ${*}
    fi
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
