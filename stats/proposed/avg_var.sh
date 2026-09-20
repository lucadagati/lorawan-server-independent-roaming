#!/bin/bash

count=0;
total=0;
sum2=0;
var=0;

########################################
###########   Arithmetic mean   ############
########################################

echo -e -n "\n\tCalculating..."

cat $1 | (while read linem; do
        total=$(echo "scale=6; $total+$linem" | bc )
        ((count++))
done

av=$(echo "scale=6; $total / $count" | bc)
li=$(echo "scale=6; ($av*$av)/2" | bc)

########################################
#####   Variance and Standard Deviation   #####
########################################

cat $1 | (while read linev; do
        diff=$(echo "scale=6; $av - $linev" | bc)
        dif2=$(echo "scale=6; $diff * $diff" | bc)
        sum2=$(echo "scale=6; $sum2 + $dif2" | bc)
done

var=$(echo "scale=6; $sum2 / $count" | bc)
stdev=$(echo "scale=6; sqrt($var)" | bc)

echo -n "Done!"
echo -e "\n\nAverage: $av"
echo "Variance: $var"
echo "Standard Deviation: $stdev"
echo -e "Area per Lipid: $li\n"))
