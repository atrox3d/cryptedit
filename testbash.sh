#!/usr/bin/env bash

PASSWORD=10010
PLAINFILE=secret.txt
ENCFILE=secret.enc

echo DECRYPT...
echo openssl enc -d -aes-256-cbc -in "${PLAINFILE}" -out "${ENCFILE}" -k "${PASSWORD}"

echo EDIT...
open -W secret.txt

echo ENCRYPT...
echo openssl enc -aes-256-cbc -out "${PLAINFILE}" -in "${ENCFILE}" -k "${PASSWORD}"

echo done

