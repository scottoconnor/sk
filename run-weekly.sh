#! /bin/sh
#
# Copyright (c) 2018, 2019, Scott O'Connor
#

CUR_YEAR=`date +"%Y"`
START_YEAR=2003

rm -f /tmp/*.html

#
# First, find out how many weeks of golf have been played this year.
#
WEEK=1
NUM_WEEKS=0
while [ ${WEEK} -le 15 ]; do
    s=`./skperf.pl -p -is -y ${CUR_YEAR} -w ${WEEK} | grep "Total Strokes" | wc -l`
    if [ $s -gt 0 ]; then
	let NUM_WEEKS+=1
    fi
    let WEEK+=1
done

WEEK=${NUM_WEEKS}

#
# Now generate the weekly stats for these week from start year to cur year
#
YEAR=${CUR_YEAR}
until [ $YEAR -lt $START_YEAR ]; do
    ./skperf.pl -s -t -h -y $YEAR -sw 1 -ew $WEEK >> /tmp/${START_YEAR}-${CUR_YEAR}-week${WEEK}.html
    ./skperf.pl -s -t -h -y $YEAR -w $WEEK >> /tmp/${START_YEAR}-${CUR_YEAR}-only-week${WEEK}.html
    echo "</br></br>" >> /tmp/${START_YEAR}-${CUR_YEAR}-week${WEEK}.html
    let YEAR-=1
done

#
# Get the stats and table for the current year, then tack the
# weekly stats below the overall stats.
#
YEAR=${CUR_YEAR}
./skperf.pl -s -t -h -y ${YEAR} > /tmp/${YEAR}.html
echo "</br></br>" >> /tmp/${YEAR}.html

until [ ${WEEK} -lt 1 ]; do
    ./skperf.pl -h -s -t -y ${YEAR} -w ${WEEK} >> /tmp/${YEAR}.html
    ./skperf.pl -h -g -y ${YEAR} -w ${WEEK} >> /tmp/${YEAR}.html
    echo "</br></br>" >> /tmp/${YEAR}.html
    let WEEK-=1
done

./stats.pl -w -h >> /tmp/${YEAR}.html
./stats.pl -c -h >> /tmp/${YEAR}.html

#
# All time table stats since START_YEAR 
#
#./skperf.pl -at -h -sy ${START_YEAR} -ey ${CUR_YEAR} > /tmp/table-totals.html
