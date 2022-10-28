#!/bin/bash

OSA_DIR="/home/int/intportalowner/integral/osa_support"

grep -Ff ${OSA_DIR}/spi-gti-scw-list.txt $1 > $2
