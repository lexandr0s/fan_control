#!/bin/bash
#######################
#Script created by 19alexrus71
#For donate - LTC: LaeSwaV5mnXJb6DgccCdHiZNKUCvbfDMFT
#############################################################




#Температура при достижении которой обороты начинают плавно повышаться
high_level=62

#Температура при которой обороты начинают плавно понижаться
low_level=60

#Температура при которой обороты сразу повышаются до very_high_fan
very_high_level=65

#Скорость кулера при достижении very_high_level
very_high_fan=70

#Скорость кулера ниже которой обороты уже не регулируются и переключаются в авторежим
min_fan=35

#Максимальная скорость кулера
max_fan=100

#Пауза между циклами проверки в секундах
PAUSE=10

#Минимальный порог загрузки карт. Если меньше - считается, что майнинг не работает
min_using=50

#Количество циклов с ошибкой (или низкой загрузкой карт), при достижении которого происходит reboot
error_level=15

#Включение/выключение watchdog. Отключить: watch_dog=0. Мониторинг будет происходить, но перезагрузка отключена
watch_dog=1



#########################################################################
count=$(sudo nvidia-smi -i 1 --query-gpu=count --format=csv,noheader,nounits)
error_flag=0
error_count=0

while (true)
do
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

for (( i=0; i < $count; i++ ))
do
echo
res_req=0
fan=$(sudo nvidia-smi -i $i --query-gpu=fan.speed --format=csv,noheader,nounits)
res_req=$?
if [ $res_req -ne 0 ]
then
echo "Error get data from card "$i
error_flag=1
error_msg="Error get data from card "$i
continue
fi
res_req=0
temp=$(sudo nvidia-smi -i $i --query-gpu=temperature.gpu --format=csv,noheader,nounits)
res_req=$?
if [ $res_req -ne 0 ]
then
echo "Error get data from card "$i
error_flag=1
error_msg="Error get data from card "$i
continue
fi
res_req=0
using=$(sudo nvidia-smi -i $i --query-gpu=utilization.gpu --format=csv,noheader,nounits)
res_req=$?
if [ $res_req -ne 0 ]
then
echo "Error get data from card "$i
error_flag=1
error_msg="Error get data from card "$i
continue
fi
if [ $using -lt $min_using ]
then
error_flag=1
error_msg="Using card "$using"%"
fi


echo "Using Card "$i": "$using"%."
control=$(nvidia-settings -q "[gpu:"$i"]/GPUFanControlState" -t)

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
nvidia-settings -a "[gpu:"$i"]/GPUFanControlState=1" > /dev/null 2>&1
nvidia-settings -a "[fan:"$i"]/GPUTargetFanSpeed="$speed > /dev/null 2>&1
continue
fi

if [ $temp -lt $low_level ]
then
if [ $fan -le $min_fan ]
then
nvidia-settings -a "[gpu:"$i"]/GPUFanControlState=0" > /dev/null 2>&1
echo "Fan "$i": "$fan" Temperature "$i": "$temp
continue
else
if [ $control -ne 0 ]
then
speed=$(( $fan - 1 ))
nvidia-settings -a "[gpu:"$i"]/GPUFanControlState=1" > /dev/null 2>&1
nvidia-settings -a "[fan:"$i"]/GPUTargetFanSpeed="$speed > /dev/null 2>&1
echo "Fan "$i": "$fan" Temperature "$i": "$temp ". Is very low! Decrease fan speed to "$speed
continue
fi
fi
fi

echo "Fan "$i": "$fan" Temperature "$i": "$temp

done

sleep $PAUSE
done
