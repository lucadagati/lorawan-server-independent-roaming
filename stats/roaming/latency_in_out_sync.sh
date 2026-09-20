#!/bin/bash

i=0
sub=0
send=0

while [[ $i -lt 10000 ]]; do
    ((i++))
    sub=`paste sub_sort.txt | awk -v i=$i -v j=2 'FNR == i {print $j}'`
    send=`paste send_sort.txt | awk -v i=$i -v j=2 'FNR == i {print $j}'`
    sub=${sub#0}
    send=${send#0}
    sub=${sub#0}
    send=${send#0}
    echo "$send"
    echo "$sub"
  if [[ $((send-sub)) -ne 0 ]]; then
    awk -v n=$i 'NR == n {next} {print}' send_sort.txt > tmpfile && mv tmpfile send_sort.txt
    echo "DELETE"
    ((i--))
    continue
  fi
done
echo 'All Done!'

#sed -i '33d' file
#paste sub_sort.txt send_sort.txt | awk '{printf("%d\n",($2-$5));}'

