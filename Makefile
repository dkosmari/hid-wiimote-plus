PACKAGE := hid-wiimote
VERSION := 0.5
DISTDIR := $(PACKAGE)-$(VERSION)

FILES := \
	hid-ids.h \
	hid-wiimote.h \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-modules.c

obj-m += hid-wiimote.o
hid-wiimote-objs += hid-wiimote-core.o hid-wiimote-debug.o hid-wiimote-modules.o

KDIR := /lib/modules/$(shell uname -r)/build
INSTALL_MOD_DIR := kernel/drivers/hid
HID_DIR := /lib/modules/$(shell uname -r)/kernel/drivers/hid

.PHONY: all clean install replace dist

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean
	$(RM) -r $(DISTDIR)

install:
	make -C $(KDIR) M=$(PWD) modules_install
	depmod -A

replace: install
	-chmod a-r $(HID_DIR)/hid-wiimote.ko*

dist:
	mkdir -p $(DISTDIR)
	cp Makefile README $(FILES) $(DISTDIR)/
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) -r $(DISTDIR)
