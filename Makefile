# this is used for packaging, to distinguish from the original
PACKAGE := hid-wiimote-plus

# this is used to name the module file, so it must match the original to override it
MODULE := hid-wiimote

VERSION := 0.9.2+

DISTDIR := $(PACKAGE)-$(VERSION)

DISTFILES := \
	99-wiimote.hwdb \
	99-wiimote.rules \
	COPYING \
	dkms.conf.in \
	gamepad.rst \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-flt.c \
	hid-wiimote-flt.h \
	hid-wiimote-modules.c \
	hid-wiimote.h \
	Kbuild \
	Makefile \
	README.md


KDIR ?= /lib/modules/$(shell uname -r)/build
SRCTREE ?= /usr/src

SRCDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))


.PHONY: all clean dist install uninstall


all:
	make --directory=$(KDIR) M=$(SRCDIR) WIIMOTE_MODULE_VERSION=$(VERSION)


clean:
	$(info cleaning up)
	make --directory=$(KDIR) M=$(SRCDIR) clean
	$(RM) --recursive $(DISTDIR)
	$(RM) dkms.conf


dist:
	mkdir $(DISTDIR)
	cp --target-directory=$(DISTDIR) $(DISTFILES)
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) --recursive $(DISTDIR)


install:
	-cp --target-directory=/etc/udev/hwdb.d 99-wiimote.hwdb
	systemd-hwdb update
	-cp --target-directory=/etc/udev/rules.d 99-wiimote.rules
	$(RM) --recursive $(SRCTREE)/$(DISTDIR)
	mkdir --parents $(SRCTREE)/$(DISTDIR)
	cp --target-directory=$(SRCTREE)/$(DISTDIR) $(DISTFILES)
	make --directory=$(SRCTREE)/$(DISTDIR) dkms.conf
	dkms add -m $(PACKAGE) -v $(VERSION)
	dkms build -m $(PACKAGE) -v $(VERSION)
	dkms install -m $(PACKAGE) -v $(VERSION)


uninstall:
	$(RM) /etc/udev/hwdb.d/99-wiimote.hwdb
	$(RM) /etc/udev/rules.d/99-wiimote.rules
	-dkms remove -m $(PACKAGE) -v $(VERSION) --all
	$(RM) --recursive $(SRCTREE)/$(DISTDIR)


dkms.conf: dkms.conf.in
	sed 	-e "s/@PACKAGE@/$(PACKAGE)/g" \
		-e "s/@VERSION@/$(VERSION)/g" \
		-e "s/@MODULE@/$(MODULE)/g" \
		$< > $@
