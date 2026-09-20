#!/bin/bash

i=0
time=0

while [[ $i -lt 10000 ]]; do
    ((i++))
    time=`paste timeh.txt | awk -v i=$i -v j=1 'FNR == i {print $j}'`
    time=${time#0}
    echo "$time"
  if [[ $time -gt $1 ]]; then
    awk -v n=$i 'NR == n {next} {print}' timeh.txt > tmpfile && mv tmpfile timeh.txt
    echo "DELETE"
    ((i--))
    continue
  fi
done
echo 'All Done!'

#sed -i '33d' file
#paste sub_sort.txt send_sort.txt | awk '{printf("%d\n",($2-$5));}'
