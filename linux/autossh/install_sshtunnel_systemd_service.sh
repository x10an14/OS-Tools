#!/bin/bash

p1=$(readlink -f $0)
p2=$(dirname $p1)

echo "$p1"
echo "$p2"


FILE=sshtunnel.session
FOLDERPATH=$(dirname $(readlink -f $0))
TEST="${FOLDERPATH}/${FILE}"
echo "$FILE"
if [[ -e $TEST ]]; then
	#sudo systemctl enable $TEST
	echo "yay!"
else
	echo "Did not find '$FILE' in the folder of this script!"
fi

exit 0

