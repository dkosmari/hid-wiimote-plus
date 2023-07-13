# this is used for packaging, to distinguish from the original
PACKAGE := hid-wiimote-plus

# this is used to name the module file, so it must match the original to override it
MODULE := hid-wiimote

# make sure to also update the version inside hid-wiimote-core.c
VERSION := 0.8.4

DISTDIR := $(PACKAGE)-$(VERSION)

DISTFILES := \
	99-wiimote.rules \
	COPYING \
	dkms.conf.in \
	gamepad.rst \
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


install: dkms.conf
	$(RM) --recursive $(SRCTREE)/$(DISTDIR)
	mkdir --parents $(SRCTREE)/$(DISTDIR)
	cp --target-directory=$(SRCTREE)/$(DISTDIR) $(DISTFILES) dkms.conf
	-cp --target-directory=/etc/udev/rules.d 99-wiimote.rules
	dkms add -m $(PACKAGE) -v $(VERSION)
	dkms build -m $(PACKAGE) -v $(VERSION)
	dkms install -m $(PACKAGE) -v $(VERSION)


uninstall:
	$(RM) /etc/udev/rules.d/99-wiimote.rules
	-dkms remove -m $(PACKAGE) -v $(VERSION) --all
	$(RM) --recursive $(SRCTREE)/$(DISTDIR)


dkms.conf: dkms.conf.in
	sed 	-e "s/@PACKAGE@/$(PACKAGE)/g" \
		-e "s/@VERSION@/$(VERSION)/g" \
		-e "s/@MODULE@/$(MODULE)/g" \
		$< > $@
