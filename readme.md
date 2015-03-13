# Порт проекта u16_tsconf на отладочную плату Zr-Tech WXEDA

Порт оригинального проекта конфигурации TS-Conf для платы Reverse U16 [https://code.google.com/p/reverse-u16/](https://code.google.com/p/reverse-u16/), Автор оригинального проекта: MVV
``
## Модификация платы:

Плата достаточно бедно укомплектована, для полноценной работы проекта необходимо провести ряд модификаций с паяльником для того,
чтобы сделать поддержку SD-карты и задействовать освободившиеся пины (под SD-карту и вывод звука, в частности).

1. Необходимо выпаять 7-сегментный индикатор и впаять вместо него pin header 2x6
2. Необходимо выпаять IR-приемник и паять вместо него pin header 1x3
3. Необходимо выпаять ВЧ-разъем
4. Необходимо заменить (опционально) резисторные сборки RP10-RP12 300 Ом на сборки 0 Ом
5. Собрать shield-плату [https://github.com/andykarpov/wxeda-sdcard-shield](https://github.com/andykarpov/wxeda-sdcard-shield), которая будет служить адаптером SD-карты + линейный выход звука

Данная модификация также подходит для таких проектов:

1. Радио-86РК для WXEDA [https://github.com/andykarpov/radio-86rk-wxeda](https://github.com/andykarpov/radio-86rk-wxeda)
2. Специалист для WXEDA [https://github.com/andykarpov/specialist-wxeda](https://github.com/andykarpov/specialist-wxeda)
3. Вектор-06Ц для WXEDA [https://code.google.com/p/vector06cc/](https://code.google.com/p/vector06cc/) (svn-ветка **wxeda-cycloneiv**)
4. Speccy для WXEDA [https://github.com/andykarpov/speccy-wxeda](https://github.com/andykarpov/speccy-wxeda)

Фото девборды после модификаций:

![image](https://farm9.staticflickr.com/8563/16123145773_dfebd94346.jpg)

Фото девборды с SD-адаптером:

![image](https://farm4.staticflickr.com/3948/15601327551_425db1abcc.jpg)

## Подготовка:

Данной конфигурацией поддерживается загрузка ПЗУ:

1. с FAT32 SD карты
2. либо со встроенной на плате SPI flash памяти W25Q32 объемом 4МБ. 

По-умолчанию в проект подключен FAT32 загрузчик (loader_fat32), который ищет файл ROMS/ZXEVO.ROM на SD-карте и загружает его. 

Для тех, кому этот вариант кажется слишком простым, вот вариант записи ПЗУ на SPI flash W25Q32 для SPI-загрузчика (при этом rom.vhd в проекте нужно перестроить на использование ../loader/loader.hex вместо loader_fat32/loader.hex):

### Запись ROM на W25Q32

Необходимо записать на встроенную SPI Flash Winbond W25Q32 образ roms/W25Q32.ROM.
Так как у автора не было специального программатора, но была под рукой Raspberry Pi, было найдено решение, как практически безболезненно
прошить впаянную на девборку SPI флешку:

- В девборду заливается прошивка [https://github.com/andykarpov/speccy-wxeda-sdcard-bridge](https://github.com/andykarpov/speccy-wxeda-sdcard-bridge) через JTAG, которая реализует соединение пинов W25Q32 с внешними пинами гребенки
- Пины гребенки **2,3,4,5 (DI,DO,CLK,CS)**, подключенные (виртуально) к W25Q32 и **GND** (средний пин гребенки 1x3 от выпаянного IR-приемника) 
    соединяются с **GPIO** пинами Raspberry Pi (**19,21,23,24,25** соответственно). Подробнее: [http://flashrom.org/RaspberryPi](http://flashrom.org/RaspberryPi)
- На Raspberry Pi установлена последняя версия Raspbian
- На Raspberry Pi скачивается и устанавливается проект flashrom - [http://flashrom.org/Downloads](http://flashrom.org/Downloads) + необходимые зависимости для его сборки
- включается модуль ядра spi (через raspi-config или руками - modprobe spi_bcm2708 и modprobe spidev)
- заливка прошивки:
    - проверяем, находится ли флешка: `./flashrom -p linux_spi:dev=/dev/spidev0.0` 
    - если находится - заливаем: `./flashrom -p linux_spi:dev=/dev/spidev0.0 -w /путь/к/W25Q32.ROM`
    - успешная запись длится порядка 30 секунд

фото этапа программирования с помощью flashrom: 

![image](https://farm8.staticflickr.com/7619/16717196616_d40a3a308b.jpg)

### Подготовка SD-карты

- Взять чистую SD-карту, отформатированную в FAT32
- Записать в папку ROMS/ файл ZXEVO.ROM
- Записать в корень файл **softwares/boot.$C** 
- Скачать дистрибутив **Wild Commander** [http://zx-evo-fpga.googlecode.com/hg/pentevo/soft/WC/wc.rar](http://zx-evo-fpga.googlecode.com/hg/pentevo/soft/WC/wc.rar), распаковать и переписать на SD-карту директорию **WC**
- Записать необходимое количество Ваших образов TRD, SCL, TAP, музыки в формате PT3, и чего угодно, что поддерживает WC, можно распихивать их по вложенным директориям.
- Подробнее о WC: [http://tslabs.info/forum/viewtopic.php?f=26&t=143](http://tslabs.info/forum/viewtopic.php?f=26&t=143)

### Заливка jic в конфигурационную флеш девборды:

- Открыть проект в Quartus 13
- Открыть Programmer
- Выбрать подготовленный файл tsconf_wxeda.jic
- Выбрать подключенный USB Blaster
- Запустить программирование
- После успешной заливки выключить и включить девборду
- Profit :)

## Использование TS-CONF на WXEDA 
Итак, после подачи питания на плату происходит следующее:

1. FPGA заливает в себя конфигурацию с конфигурационной флешки EPCS4 и стартует ее
2. Далее запускается конфигурация и управление передается loader'у;
3. FAT32 Loader автоматически пытается загрузить ROMS/ZXEVO.ROM с FAT32 SD-карты, SPI Loader - загружает содержимое флешки W25Q32 в специальную область ОЗУ (SDRAM), отведенную под хранение ПЗУ
4. Управление передается TS-BIOS Setup utility

Чтобы запустить образ TRD или SCL, на него нужно наступить Enter'ом, при этом образ примонтируется. Далее сброс (F12), попадаем в TR-DOS. Если диск автозагрузочный - запустится сразу, иначе - LIST + LOAD "файл"

Чтобы запустить программу в формате SPG, на нее достаточно просто наступить Enter'ом в WC.

Чтобы прослушать музыку в формате PT3, достаточно нажать Enter (музыкальный проигрыватель является одним из плагинов к WC).

### Особенности

1. В проекте отсутствует микросхема для RTC, поэтому ее конфигурирование было выключено из загрузкича.
2. Так как Video DAC конфигурации TS-CONF использует по 8 бит на цвет, а на плате WXEDA используется вариант 5:6:5 для VGA, используеются только старшие биты.

### Рабочие функциональные кнопки

- F12 - Сброс (в выбранный банк, указанный в настройках TS-BIOS)
- Shift + F12 - Сброс + запуск Wild Commander
- Ctrl + F12 - Сброс + запуск TS-BIOS
- Возможно есть еще какие-то, я пока не осилил :)

Приятного использования :)