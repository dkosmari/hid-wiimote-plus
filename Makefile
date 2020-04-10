PACKAGE := hid-wiimote
VERSION := 0.7
DISTDIR := $(PACKAGE)-$(VERSION)

FILES := \
	hid-ids.h \
	hid-wiimote.h \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-modules.c

obj-m += hid-wiimote.o
hid-wiimote-objs += hid-wiimote-core.o hid-wiimote-debug.o hid-wiimote-modules.o

KERNEL_VERSION := $(shell uname -r)

KDIR := /lib/modules/$(KERNEL_VERSION)/build

INSTALL_MOD_DIR := kernel/drivers/hid

HID_DIR := /lib/modules/$(KERNEL_VERSION)/kernel/drivers/hid

ORIGINAL_MODULE_PATH := $(wildcard $(HID_DIR)/hid-wiimote.ko*)
ifeq (,$(wildcard $(ORIGINAL_MODULE_PATH)))
	$(warning "Original module not found.")
endif
ifeq ($(suffix $(ORIGINAL_MODULE_PATH)),.backup)
	ORIGINAL_MODULE_PATH := $(ORIGINAL_MODULE_PATH:.backup=)
endif

BACKUP_MODULE_PATH := $(ORIGINAL_MODULE_PATH).backup

NEW_MODULE_PATH := /lib/modules/$(KERNEL_VERSION)/extra/hid-wiimote.ko


.PHONY: all clean install replace dist

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean
	$(RM) -r $(DISTDIR)

install:
	make -C $(KDIR) M=$(PWD) modules_install
	-( test -n "$(ORIGINAL_MODULE_PATH)" && \
		mv $(ORIGINAL_MODULE_PATH) $(BACKUP_MODULE_PATH) )
	depmod -A

uninstall:
	-$(RM) $(NEW_MODULE_PATH)
	-( test -n "$(ORIGINAL_MODULE_PATH)" && \
		mv $(BACKUP_MODULE_PATH) $(ORIGINAL_MODULE_PATH) )
	depmod -A

dist:
	mkdir -p $(DISTDIR)
	cp Makefile README gamepad.rst $(FILES) $(DISTDIR)/
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) -r $(DISTDIR)
