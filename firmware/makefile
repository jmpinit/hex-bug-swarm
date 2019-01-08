FIRMWARE_NAME = firmware
FREQUENCY = 16000000U

CFLAGS = -g -Wall -O2 -mmcu=atmega328p -DF_CPU=$(FREQUENCY)
LDFLAGS = -Iinc

$(FIRMWARE_NAME).hex: firmware.obj
	avr-objcopy -j .text -j .data -O ihex $^ $@

$(FIRMWARE_NAME).obj: main.c
	avr-gcc $(CFLAGS) $(LDFLAGS) -o $@ $^

flash: firmware.hex
	avrdude -c usbtiny -p atmega328p -U flash:w:$<

fuses:
	avrdude -c usbtiny -p atmega328p -U lfuse:w:0xde:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m

.PHONY: flash, fuses

