obj-m += hid-wiimote.o
hid-wiimote-objs += hid-wiimote-core.o hid-wiimote-debug.o hid-wiimote-modules.o



all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
