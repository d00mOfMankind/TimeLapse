#!/usr/bin/env bash
per=100
lstring="="
load=""
point=">"
dot="."
dots=""

while [ $per -ge 1 ]; do
	dots=$dots$dot
	per=$((per-1))
done

while [ $per -le 100 ]; do
	echo -ne "[$load$point$dots] $per %" \\r
	load=$load$lstring
	dots=${dots%?}
	per=$((per+1))
	sleep 0.05
done

echo ""