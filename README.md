# Автоматическое управление вентиляторами видеокарт Nvidia для linux в том числе HiveOS
## Функционал контроля температуры:
- Задается коридор температур (по умолчанию 58-60) в котором скрипт будет пытаться держать карты.
- При снижении температуры ниже нижнего порога - происходит плавное снижение оборотов кулера.
- При достижении верхнего порога - плавное увеличение оборотов.
- При достижении второго порога (по умолчанию 65)- сразу включается турборежим кулера (по умолчанию 70), и после этого плавное увеличение вплоть до максимальных оборотов, пока температура не снизится.
- При снижении оборотов ниже минимальных (по умолчанию 35) - происходит переключение на автоматическое управление кулерами. Полезно при зимнем балконном майнинге, чтобы не крутить вентиля, когда картам и так холодно. (на многих картах вентиля просто отключаются ниже определенной температуры)

## Функционал WatchDog (можно отключить):
- Считываются значения загрузки карт.
- В случае ошибки получения данных (отвал карты). Или в случае снижения загрузки карты ниже установленного порога (не работает майнер), начинается обратный отсчет. Если по прошествии заданного количества циклов - загрузка карт не восстанавливается - происходит перезагрузка с одновременной записью даты ребута и его причины в ~/watchdog.log

Входные переменные для настройки задаются в начале скрипта. В скрипте есть описание переменных. Запускать желательно в отдельном окне терминала или в screen

## Использование в HiveOS
- скачать архив в домашнюю директорию /home/user

> cd /home/user

> wget https://github.com/lexandr0s/fan_control/archive/v2.0.tar.gz

- распаковать архив

> tar -xvf v2.0.tar.gz

- присвоить скриптам права на исполнение

> chmod +x fan_control-2.0/*

-скопировать скрипт управления вентиляторами и скрипт автозапуска и скрипт в домашнуюю директорию

> cp fan_control-2.0/* /home/user

-перезагрузить риг или запустить скрипт без перезагрузки выполнив команду:

> screen -dmS fan /home/user/fan.sh


После этого скрипт будет запускаться при старте рига в фоновом режиме в screen.

Восстановить окно скрипта и понаблюдать за его работой можно с помощью команды

> screen -r fan

Отключиться от окна скрипта:

> Ctrl+A

> D


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Change Log:
v.2.0
Скрипт кардинально переработан. 
Опрос карт теперь происходит единожды за цикл.
Добавлен блок предотвращения возможных конфликтов при сборе данных с карт со стороны HiveOS.
Достигнуто значительное увеличение скорости работы и стабильности.

### *For donate*

*LTC:* LaeSwaV5mnXJb6DgccCdHiZNKUCvbfDMFT

*ETH:* 0x4e2cE16142600DE62E41b107BA06701c80C82fc4

