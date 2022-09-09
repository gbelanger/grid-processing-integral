#!/bin/bash

if [ -f nMissingScwPerRev.qdp ]
then
	rm nMissingScwPerRev.qdp
fi

echo "DEV /XS" > nMissingScwPerRev.qdp
echo "LAB F" >> nMissingScwPerRev.qdp
echo "VIEW 0.1 0.2 0.9 0.8" >> nMissingScwPerRev.qdp
echo "TIME OFF" >> nMissingScwPerRev.qdp
echo "CS 1.3" >> nMissingScwPerRev.qdp
echo "LW 3" >> nMissingScwPerRev.qdp
echo "LINE STEP" >> nMissingScwPerRev.qdp
echo "LABEL X \"Number of Missing Scw per Rev\"" >> nMissingScwPerRev.qdp
echo "LABEL Y \"Number of Revs\"" >> nMissingScwPerRev.qdp
echo "!   DATA" >> nMissingScwPerRev.qdp

while ((i <= 15))
do
	i=$((i+1))
	getListOfRevsToRedo.sh $i >> nMissingScwPerRev.qdp
done
