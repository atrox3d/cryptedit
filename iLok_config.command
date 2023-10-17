#!/usr/bin/env bash

#############################################################################
#
# CONFIG
#
#############################################################################
#
# percorsi base
#
SCRIPTPATH="$(dirname "${0}")"          # percorso script == percorso dati
DATAPATH="$(dirname "${0}")"            # percorso dati == percorso script
#
# nomi files
#
LOGFILENAME=$(basename "${0}" .command).log # <nome script>.log
DATAFILENAME=iLok.xlsx                      # nome file dati
ENCFILENAME=iLok.auth                       # nome file criptato
ENCRYPT="${SCRIPTPATH}/encrypt"             # script encryption
DECRYPT="${SCRIPTPATH}/decrypt"             # script decryption
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
    echo "FATAL | Termino programma"
    echo "FATAL | per consultare log aprire: ${LOGFILE}"
    exit 1
}
#
# ritorna timestamp corrente
#
function timestamp()
{
    echo "$(date '+%Y/%m/%d-%H:%M:%S')"
}
#
# cancella file dati in chiaro
#
function delete_datafile()
{
    echo -n "INFO  | CANCELLO ${DATAFILE}..."
    rm "${DATAFILE}"
}
#
# decripta il file
#
function decrypt()
{
    local errorcode
    "${DECRYPT}" "${ENCFILE}" "${DATAFILE}" "${ENCPASS}"
    errorcode=$?
    echo -e "\nINFO  | encrypt error code: ${errorcode}"
    return ${errorcode}
}
#
# cripta il file
#
function encrypt()
{
    local errorcode
    "${ENCRYPT}" "${ENCFILE}" "${DATAFILE}" "${ENCPASS}"
    errorcode=$?
    echo -e "\nINFO  | encrypt error code: ${errorcode}"
    return ${errorcode}
}
#
# chiede password: se vuota esce male
#
function get_password()
{
    read -sp 'PASSWORD: ' ENCPASS 2>&1
    echo ""
    [ -z "${ENCPASS}" ] && return 1 || return 0
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

    echo -n "INFO  | controllo files..."
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
    fi

    #
    # il file dati non esiste, procedo alla decrittazione
    #
    echo "Ok"
    #
    # chiedo password prima di iniziare
    #
    while ! get_password
    do
        echo "ERROR | e' necessario inserire una password per continuare"
    done

    echo -n "INFO  | DECRITTO ${ENCFILE}..."
    if decrypt
    then
        echo "Ok"
    else
        #
        # openssl ha restituito un errore
        # cancello file dati errato ed esco
        #
        echo ""
        delete_datafile            
        die "errore decriptando ${ENCFILE}, verificare che la password sia corretta!"
    fi

    #
    # se non ci sono errori il file dati e' presente
    # lo apro con editor di sistema e attendo...
    #
    echo -n "INFO  | EDIT ${DATAFILE}..."
    if open -W "${DATAFILE}"
    then
        echo "Ok"
    else
        #
        # l'editor ha resistuito un errore
        # TODO: provare a catturare errore
        #
        die "errore aprendo ${DATAFILE} per editing !!!"
    fi

    #
    # l'editing e' andato a buon fine
    # e l'editor e' stato chiuso
    # procedo alla crittografia del file
    #
    echo -n "INFO  | CRIPTO ${ENCFILE}..."
    if encrypt
    then
            echo "Ok"
    else
        #
        # openssl ha restituito un errore
        #
        die "errore decriptando ${ENCFILE} !!!"
    fi

    #
    # la crittografia e' andata a buon fine
    # procedo con la cancellazione del file dati
    # TODO: aggiungere check esistenza file crittato
    #
    if delete_datafile
    then
        echo "Ok"
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
} 2>>"${LOGFILE}" | tee -a "${LOGFILE}" # stderr to logfile, stdout to terminal and logfile
