#!/usr/bin/env bash

PASSWORD=10010          # TODO: mettere password in env
PLAINFILE=secret.txt
ENCFILE=secret.enc

if  [ ! -f ${PLAINFILE} ]
then
    echo -n "DECRITTO ${ENCFILE}..."
    openssl enc -d -aes-256-cbc -in "${ENCFILE}" -out "${PLAINFILE}" -k "${PASSWORD}" 2> dec-error.log && {
        echo "Ok"
    } || {
        echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
        echo "Termino programma"
        exit 1
    }
    
else
    echo "ERRORE | il file ${PLAINFILE} esiste"
    exit 2
fi

echo -n "EDIT ${PLAINFILE}..."
open -W secret.txt && {
    echo "Ok"
} || {
    echo "ERRORE aprendo ${PLAINFILE} per editing !!!"
    exit 3
}

echo -n "CRITTO ${ENCFILE}..."
openssl enc -aes-256-cbc -out "${ENCFILE}" -in "${PLAINFILE}" -k "${PASSWORD}"  2> enc-error.log && {
        echo "Ok"
} || {
    echo "ERRORE DECRITTANDO ${ENCFILE} !!!"
    echo "Termino programma"
    exit 4
}

echo -n "CANCELLO ${PLAINFILE}..."
rm ${PLAINFILE} && {
    echo "Ok"
} || {
    echo "ERRORE cancellando ${PLAINFILE} !!!"
    exit 3
}
echo FINE


