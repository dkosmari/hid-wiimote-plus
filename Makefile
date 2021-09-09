PACKAGE := hid-wiimote

VERSION := 0.7

DISTDIR := $(PACKAGE)-$(VERSION)

DISTFILES := \
	gamepad.rst \
	hid-ids.h \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-modules.c \
	hid-wiimote.h \
	Kbuild \
	Makefile \
	README


KVERSION := $(shell uname -r)

KBASE := /lib/modules/$(KVERSION)

KDIR ?= $(KBASE)/build

ORIGINAL_MODULE := $(wildcard $(KBASE)/kernel/drivers/hid/hid-wiimote.ko*)
ifeq ($(suffix $(ORIGINAL_MODULE)),.backup)
	ORIGINAL_MODULE := $(ORIGINAL_MODULE:.backup=)
endif

BACKUP_MODULE := $(ORIGINAL_MODULE).backup

NEW_MODULE := $(wildcard $(KBASE)/extra/hid-wiimote.ko*)


ifneq (,$(wildcard $(ORIGINAL_MODULE)))
FOUND_ORIGINAL := yes
endif

ifneq (,$(wildcard $(BACKUP_MODULE)))
FOUND_BACKUP := yes
endif

ifneq (,$(NEW_MODULE))
FOUND_NEW := yes
endif



.PHONY: default clean install uninstall dist


default:
	make -C $(KDIR) M=$(PWD) modules


clean:
	make -C $(KDIR) M=$(PWD) clean
	$(RM) -r $(DISTDIR)


install:
ifeq ($(FOUND_ORIGINAL),yes)
	$(info Creating backup.)
	mv $(ORIGINAL_MODULE) $(BACKUP_MODULE)
else
	$(warning There is no original file to backup.)
endif
	make -C $(KDIR) M=$(PWD) modules_install
	depmod -A


uninstall:
ifeq ($(FOUND_NEW),yes)
	-$(RM) $(NEW_MODULE)
endif
ifeq ($(FOUND_BACKUP),yes)
	$(info Restoring backup.)
	mv $(BACKUP_MODULE) $(ORIGINAL_MODULE)
else
	$(warning No backup found to restore.)
	$(warning You may need to reinstall the kernel package to restore it.)
endif
	depmod -A


dist:
	mkdir -p $(DISTDIR)
	cp $(DISTFILES) $(DISTDIR)/
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) -r $(DISTDIR)
