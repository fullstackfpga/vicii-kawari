#!/bin/bash
# Usage
# ./test_all [prg]
#
# If prg omitted, all tests run.

input="tests.txt"
while read -r line
do
   stringarray=($line)

   #if [ "${stringarray[2]}" == "screenshot" ]
   #then

	i=${stringarray[0]}

	j=`basename $i`
	k=`dirname $i`

	if [ "${stringarray[1]}" == "NTSC" ]
	then
		standard="-ntsc"
		model="6567"
		chip="0"
	elif [ "${stringarray[1]}" == "NTSCOLD" ]
	then
		standard="-ntsc"
		model="6567r56a"
		chip="2"
	else
		standard="-pal"
		model="6569"
		chip="1"
	fi

	delay="6"
	if [[ $i == +(*spritecrunch*) ]]
	then
		delay="8"
	elif [[ $i == +(*reg_timing*) ]]
	then
		delay="12"
	elif [[ $i == +(*lightpen*) ]]
	then
		delay="12"
	elif [[ $i == +(*lft-safe-vsp*) ]]
	then
		delay="19"
	fi

	pushd /shared/Vivado/vicii-vice-3.4
        ./src/x64sc -sounddev dummy $standard -VICIImodel $model \
		"/shared/Vivado/vicii/tests/$i" 2> stderr &
	popd

	sleep $delay

	rm -f screenshot.bmp
	../simulator/obj_dir/Vtop -w -z -x -c $chip

	convert screenshot.bmp -scale 50% $k/fpga_$j.png
	mv /shared/Vivado/vicii-vice-3.4/screenshot.png $k/vice_$j.png
	mv /shared/Vivado/vicii-vice-3.4/stderr $k/vice_$j.log

   #fi

done < "$input"
