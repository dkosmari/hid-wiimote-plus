PACKAGE := hid-wiimote

VERSION := 0.8

DISTDIR := $(PACKAGE)-$(VERSION)

DISTFILES := \
	dkms.conf \
	gamepad.rst \
	hid-ids.h \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-modules.c \
	hid-wiimote.h \
	Kbuild \
	Makefile \
	README


KDIR ?= /lib/modules/$(shell uname -r)/build
SRCTREE ?= /usr/src

SRCDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))


.PHONY: default build clean dist install uninstall


default:
	$(info Run `make install` or `make uninstall` as root.)


build:
	make -C $(KDIR) M=$(SRCDIR)


clean:
	$(info cleaning up)
	make -C $(KDIR) M=$(SRCDIR) clean
	$(RM) -r $(DISTDIR)


dist:
	mkdir -p $(DISTDIR)
	cp $(DISTFILES) $(DISTDIR)/
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) -r $(DISTDIR)


install:
	rm -rf $(SRCTREE)/$(PACKAGE)-$(VERSION)
	cp -r $(SRCDIR) $(SRCTREE)/$(PACKAGE)-$(VERSION)
	dkms add -m $(PACKAGE) -v $(VERSION)
	dkms build -m $(PACKAGE) -v $(VERSION)
	dkms install -m $(PACKAGE) -v $(VERSION)


uninstall:
	dkms remove -m $(PACKAGE) -v $(VERSION) --all
	rm -rf /usr/src/$(PACKAGE)-$(VERSION)
