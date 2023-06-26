#!/usr/bin/env bash

PASSWORD=10010          # TODO: la password va DIGITATA
DATAFILE=secret.txt     # percorso file dati
ENCFILE=secret.enc      # percorso file criptato

#
# TODO: creare un unico log
# TODO: aggiungere percorso assoluto files
#       oppure gestire CWD
#

#
# il file dati non dovrebbe esistere, pena la sovrascrittura
# dei dati durante la decrittazione
#
if  [ ! -f ${DATAFILE} ]
then
    #
    # il file dati non esiste, procedo alla decrittazione
    #
    echo -n "DECRITTO ${ENCFILE}..."
    openssl enc -d -aes-256-cbc -in "${ENCFILE}" -out "${DATAFILE}" -k "${PASSWORD}" 2> dec-error.log && {
        echo "Ok"
    } || {
        #
        # openssl ha restituito un errore
        #
        echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
        echo "Termino programma"
        exit 1
    }
else
    #
    # il file dati esiste, impossibile continuare
    #
    echo "ERRORE | il file ${DATAFILE} esiste"
    exit 2
fi

#
# se non ci sono errori il file dati e' presente
# lo apro con editor di sistema e attendo...
#
echo -n "EDIT ${DATAFILE}..."
open -W secret.txt && {
    echo "Ok"
} || {
    #
    # l'editor ha resistuito un errore
    # TODO: provare a catturare errore
    #
    echo "ERRORE aprendo ${DATAFILE} per editing !!!"
    exit 3
}

#
# l'editing e' andato a buon fine
# e l'editor e' stato chiuso
# procedo alla crittografia del file
#
echo -n "CRITTO ${ENCFILE}..."
openssl enc -aes-256-cbc -out "${ENCFILE}" -in "${DATAFILE}" -k "${PASSWORD}"  2> enc-error.log && {
        echo "Ok"
} || {
    #
    # openssl ha restituito un errore
    #
    echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
    echo "Termino programma"
    exit 4
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
    exit 3
}

echo FINE


