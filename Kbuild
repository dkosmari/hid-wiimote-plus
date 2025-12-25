CFLAGS_MODULE := -DWIIMOTE_MODULE_VERSION=\"$(WIIMOTE_MODULE_VERSION)\" \
              -Wall -Werror

obj-m := hid-wiimote.o
hid-wiimote-objs := hid-wiimote-core.o hid-wiimote-debug.o hid-wiimote-modules.o hid-wiimote-flt.o

# This is for Linux 6.10+
CFLAGS_hid-wiimote-flt.o += $(CC_FLAGS_FPU)
CFLAGS_REMOVE_hid-wiimote-flt.o += $(CC_FLAGS_NO_FPU)
