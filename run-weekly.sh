#! /bin/sh
#
#
# Copyright (c) 2018 Scott O'Connor
#

if [ -z $1 ]; then
	echo "usuage: run-weekly.sh <week number>"
	exit
fi

WEEK=${1}
START_YEAR=2018
END_YEAR=2010

YEAR=${START_YEAR}

rm -f /tmp/${YEAR}*.html

./skperf.pl -y -s -i -h -sy ${YEAR} -ey ${YEAR} > /tmp/${YEAR}.html


until [  $YEAR -lt $END_YEAR ]; do
	./skperf.pl -y -s -i -h -sy $YEAR -ey $YEAR -sw 1 -ew $WEEK >> /tmp/${START_YEAR}-${END_YEAR}-week${WEEK}.html
	let YEAR-=1
done


YEAR=${START_YEAR}

until [  ${WEEK} -lt 1 ]; do
	./skperf.pl -h -s -i -w -y -sy $YEAR -ey $YEAR -sw ${WEEK} -ew ${WEEK} >> /tmp/${YEAR}-weekly.html
	let WEEK-=1
done
