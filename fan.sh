#!/bin/bash
#######################
#Script created by lexandr0s
#For donate:
# LTC: LaeSwaV5mnXJb6DgccCdHiZNKUCvbfDMFT
# ETH: 0x4e2cE16142600DE62E41b107BA06701c80C82fc4
#############################################################

export DISPLAY=:0
source /home/user/fan.conf

busy=1
while [ $busy -ne 0 ]
do
	busy=$(ps aux | grep [n]vidia-smi | wc -l )
	if [ $busy -eq 0 ]
	then
		count=$(sudo nvidia-smi -i 0 --query-gpu=count --format=csv,noheader,nounits)
		nvidia-settings -a "GPUFanControlState=1" > /dev/null 2>&1
		nvidia-settings -a "GPUTargetFanSpeed="$start_speed > /dev/null 2>&1
	else
		sleep 1
	fi
done


error_flag=0
error_count=0

while (true)
do
source /home/user/fan.conf
clear





if [ $error_flag -ne 0 ]
then
	error_count=$(( $error_count + 1 ))
else
	error_count=0
fi

if [ $error_count -ne 0 ]
then
	echo "WARNING!!! Lost Card or using Card low."
	if [ $watch_dog -eq 1 ]
	then
		remain_in_cicle=$(( $error_level - $error_count ))
		remain_in_sec=$(( $remain_in_cicle * $PAUSE ))
		if [ $remain_in_cicle -le 0 ]
		then
			echo "Reboot NOW!"
			echo $(date +%d-%m-%Y\ %H:%M:%S) $error_msg >> ~/watchdog.log
			sudo reboot
		else 
			echo "Reboot in "$remain_in_sec" sec!"
		fi
	else
		echo "WatchDog disabled"
	fi
else
	if [ $watch_dog -eq 1 ]
		then
		echo "WatchDog enabled. All OK"
	else
		echo "WatchDog disabled"
	fi
fi

error_flag=0
res_req=0
busy=1
while [ $busy -ne 0 ]
do
	busy=$(ps aux | grep [n]vidia-smi | wc -l )
	if [ $busy -eq 0 ]
	then
		all_fan=($(echo "$(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits)" | tr ' ' '\n'))
		res_req=$?
		if [ $res_req -ne 0 ]
		then
			echo "Error get data from cards"
			error_flag=1
			error_msg="Error get data from cards"
			continue 2
		fi
		all_temp=($(echo "$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)" | tr ' ' '\n'))
		all_using=($(echo "$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)" | tr ' ' '\n'))
		all_control=($(echo "$(nvidia-settings -q GPUFanControlState -t)" | tr ' ' '\n'))
	else
		sleep 1
	fi
done
nv_string=""
nv_string_control=""
nv_string_speed=""

for (( i=0; i < $count; i++ ))
do
	
	fan=${all_fan[$i]}
	temp=${all_temp[$i]}
	using=${all_using[$i]}
	control=${all_control[$i]}

	echo
	if [ $using -lt $min_using ]
	then
		error_flag=1
		error_msg="Using card "$using"%"
	fi

	echo "Using Card "$i": "$using"%."
	
	if [ $temp -ge $high_level ]
	then
		if [ $fan -ge $max_fan ]
		then
			echo "Fan speed "$i": "$fan".Temperature "$i": "$temp" !!!!!!!"
			continue
		fi
		speed=$(( $fan + 2 ))
		if [ $speed -gt $max_fan ]
		then
			speed=$max_fan
		fi

		if [ $temp -ge $very_high_level ]
		then
			if [ $fan -lt $very_high_fan ]
			then
				speed=$very_high_fan
			fi
		fi
		echo "Fan "$i": "$fan" Temperature "$i": "$temp ". Is very high! Increase fan speed to "$speed
		if [ $control -eq 0 ]
		then
			nv_string_control="$nv_string_control -a [gpu:$i]/GPUFanControlState=1"
		fi
			nv_string_speed="$nv_string_speed -a [fan:$i]/GPUTargetFanSpeed=$speed"
		continue
	fi

	if [ $temp -lt $low_level ]
	then
		if [ $fan -le $min_fan ]
		then
			if [ $control -ne 0 ]
			then
				nv_string_control="$nv_string_control -a [gpu:$i]/GPUFanControlState=0"
			fi
			echo "Fan "$i": "$fan" Temperature "$i": "$temp
			continue
		else
			if [ $control -ne 0 ]
			then
				speed=$(( $fan - 1 ))
				nv_string_speed="$nv_string_speed -a [fan:$i]/GPUTargetFanSpeed=$speed"
				echo "Fan "$i": "$fan" Temperature "$i": "$temp ". Is very low! Decrease fan speed to "$speed
				continue
			fi
		fi
	fi

	echo "Fan "$i": "$fan" Temperature "$i": "$temp

done

nv_string="$nv_string_control $nv_string_speed"
if [ ${#nv_string} -gt 1 ]
then
	nvidia-settings $nv_string > /dev/null 2>&1
fi	

sleep $PAUSE
done
