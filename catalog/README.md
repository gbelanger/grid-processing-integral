# Multiscale Catalog Production

## Motivation

In order to detect new transient sources of different intensities
and duration, we need to produce mosaics on a range of timescales.

The idea is to use for each point on the sky the complete list of 
observations that include this point, and construct a series of
mosaics on timescales going from the longest, which includes all
observations, to the shortest, which we defined as a small number
of pointing or scws.

## Scripts

The parent script used to make the lists is `makeMultiScaleLists.sh`, 
which calls `coords2multiScaleLists.sh`, which relies on `get-grid-points.py`.

### get-grid-points.py 

`python get-grid-points.py 10 points.txt`

Generates equidistant points with a radius of *10* degrees apart on the celestial
 sphere in galactic coordinates and writes the output to *points.txt*.

### coords2multiScaleLists.sh

`./coords2multiScaleLists.sh fk5Coords.txt offAxisDist outputDir`

Generates lists of scws on a range of scales based on a list of FK5 coordinates
listed in *fk5Coords.txt* include all scws having a pointing axis within 
*offAxisDist* degrees of the coordinates, and writes the lists in *outputDir*.

### makeMultiScaleLists.sh

`./makeMultiScaleLists.sh step radius`

Calls `get-grid-points.py` transforms the coordinates to FK5, and calls
`coords2multiScaleLists.sh`.
