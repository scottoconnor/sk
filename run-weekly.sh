#! /bin/sh
#
#
# Copyright (c) 2018 Scott O'Connor
#

if [ -f /tmp/me ]; then
	rm /tmp/me
fi

WEEK=11
START_YEAR=2018
END_YEAR=2010

YEAR=${START_YEAR}

if [ -f /tmp/${YEAR}.html ]; then
	rm /tmp/${YEAR}.html
fi

./skperf.pl -y -s -i -h -sy ${YEAR} -ey ${YEAR} > /tmp/${YEAR}.html


if [ -f /tmp/${START_YEAR}-${END_YEAR}-week${WEEK}.html ] ; then
	rm /tmp/${START_YEAR}-${END_YEAR}-week${WEEK}.html
fi

until [  $YEAR -lt $END_YEAR ]; do
	./skperf.pl -y -s -i -h -sy $YEAR -ey $YEAR -sw 1 -ew $WEEK >> /tmp/${START_YEAR}-${END_YEAR}-week${WEEK}.html
	let YEAR-=1
done


YEAR=${START_YEAR}

if [ -f /tmp/${YEAR}-weekly.html ]; then
	rm /tmp/${YEAR}-weekly.html
fi

until [  ${WEEK} -lt 1 ]; do
	./skperf.pl -h -s -i -w -y -sy $YEAR -ey $YEAR -sw ${WEEK} -ew ${WEEK} >> /tmp/${YEAR}-weekly.html
	let WEEK-=1
done
