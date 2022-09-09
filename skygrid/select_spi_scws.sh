#!/bin/bash

OSA_DIR=${HOME}/integral/osa_support

grep -Ff ${OSA_DIR}/spi-gti-scw-list.txt $1 > $2
