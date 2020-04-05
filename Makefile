obj-m += hid-wiimote.o
hid-wiimote-objs += hid-wiimote-core.o hid-wiimote-debug.o hid-wiimote-modules.o

KDIR := /lib/modules/$(shell uname -r)/build
INSTALL_MOD_DIR := kernel/drivers/hid
HID_DIR := /lib/modules/$(shell uname -r)/kernel/drivers/hid

.PHONY: all clean install replace

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean

install:
	make -C $(KDIR) M=$(PWD) modules_install
	depmod -A

replace: install
	rm -f $(HID_DIR)/hid-wiimote.ko.xz
	rm -f $(HID_DIR)/hid-wiimote.ko
