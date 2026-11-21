#!/bin/sh
# prints: cpu% mem% battery% disk% battery-status
s1=$(head -1 /proc/stat); sleep 0.5; s2=$(head -1 /proc/stat)
cpu=$(printf '%s\n%s\n' "$s1" "$s2" | awk '{idle=$5+$6; t=0; for(i=2;i<=NF;i++) t+=$i; if(NR==1){i1=idle;t1=t} else {d=t-t1; print (d>0)?int(100*(1-(idle-i1)/d)):0}}')
mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int(100*(t-a)/t)}' /proc/meminfo)
bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
disk=$(df --output=pcent / | tail -1 | tr -dc 0-9)
echo "$cpu $mem ${bat:-100} $disk ${st:-AC}"
