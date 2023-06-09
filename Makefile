# this is used for packaging, to distinguish from the original
PACKAGE := hid-wiimote-plus

# this is used to name the module file, so it must match the original to override it
MODULE := hid-wiimote

VERSION := 0.8.3

DISTDIR := $(PACKAGE)-$(VERSION)

DISTFILES := \
	99-wiimote.rules \
	COPYING \
	dkms.conf.in \
	gamepad.rst \
	hid-ids.h \
	hid-wiimote-core.c \
	hid-wiimote-debug.c \
	hid-wiimote-modules.c \
	hid-wiimote.h \
	Kbuild \
	Makefile \
	README.md


KDIR ?= /lib/modules/$(shell uname -r)/build
SRCTREE ?= /usr/src

SRCDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))


.PHONY: default build clean dist install uninstall


default:
	$(error Run `make install` or `make uninstall` as root.)


build:
	make -C $(KDIR) M=$(SRCDIR)


clean:
	$(info cleaning up)
	make -C $(KDIR) M=$(SRCDIR) clean
	$(RM) -r $(DISTDIR)
	$(RM) dkms.conf


dist:
	mkdir -p $(DISTDIR)
	cp $(DISTFILES) $(DISTDIR)/
	tar -c -z -f $(DISTDIR).tar.gz $(DISTDIR)
	$(RM) -r $(DISTDIR)


install: dkms.conf
	$(RM) -rf $(SRCTREE)/$(PACKAGE)-$(VERSION)
	cp -r $(SRCDIR) $(SRCTREE)/$(PACKAGE)-$(VERSION)
	-cp -r 99-wiimote.rules /etc/udev/rules.d/
	dkms add -m $(PACKAGE) -v $(VERSION)
	dkms build -m $(PACKAGE) -v $(VERSION)
	dkms install -m $(PACKAGE) -v $(VERSION)


uninstall:
	$(RM) /etc/udev/rules.d/99-wiimote.rules
	-dkms remove -m $(PACKAGE) -v $(VERSION) --all
	$(RM) -r /usr/src/$(PACKAGE)-$(VERSION)


dkms.conf: dkms.conf.in
	sed 	-e "s/@PACKAGE@/$(PACKAGE)/g" \
		-e "s/@VERSION@/$(VERSION)/g" \
		-e "s/@MODULE@/$(MODULE)/g" \
		$< > $@
