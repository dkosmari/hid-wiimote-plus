# hid-wiimote-plus

This is a modification of the built-in Linux kernel module for Nintendo Wii remotes. It's
a drop-in replacement for the original module.


## Differences from the original Linux driver

The original driver does not follow the [Linux input conventions](gamepad.rst). This table shows how
the inputs are handled differently:

| Input | hid-wiimote (original) | hid-wiimote-plus | Why |
| :---- | :----------------------| :--------------- | :-- |
| Remote d-pad | Mapped to keyboard arrows. | Mapped to `BTN_DPAD_*` buttons. | It's a gamepad, not a keyboard. |
| Plus/minus buttons | Mapped to keyboard "next/prev" multimedia keys. | Mapped to `BTN_START`/`BTN_SELECT`. | The plus/minus buttons are used as start/select, sometimes it's even written on the button. |
| Sticks | Inverted Y axis. | Normal Y axis. | The Linux docs say negative Y means "up", positive Y means "down". |
| CC and CCPro | Face buttons are mapped to button names (A, B, X, Y). | Face buttons are mapped to directions (north, south, east, west). | The Linux docs say face buttons in a diamond layout should be mapped to the directions. |
| CCPro | Bogus analog TL/TR triggers. | Does not have analog TL/TR triggers. | A device should not report triggers it doesn't have. |
| Balance Board | The 4 pressure sensors are combined as a pair of 2-D axes. | The 4 pressure sensors are reported as 4 separated axes. | The pressure sensors do not represent position in any way, they shouldn't be reported as such. |
| Accelerometer | Does not report `INPUT_PROP_ACCELEROMETER` and uses the wrong axes (RX, RY, RZ). | Reports `INPUT_PROP_ACCELEROMETER`, and uses the correct axes (X, Y, Z). | For "accelerometer" inputs, the left axes are reserved for linear acceleration, the right axes are for angular acceleration. |
| Motion Plus | Does not report `INPUT_PROP_ACCELEROMETER`. | Reports `INPUT_PROP_ACCELEROMETER`. | Applications won't be fooled into thinking it's a positional input. |
| CC and CCPro | Has an option to emulate the left stick with the d-pad. | Does not have this option. | Emulating/remapping input does not belong to a device driver. |

Battery reporting is more detailed, and there's special handling for the Wii U Pro
Controller and Balance Board devices.

In the debugfs interface, the original driver only exposes the EEPROM as read-only; now
it's also writeable, and the registers are also available.

Memory allocations are now tied to the device node; this ensures no memory can leak after
the device disconnects.


## Installation

You will need the kernel development headers in your system. Additionally, you will need
the **DKMS** package; it allows for easy install and uninstall, and will automatically
rebuild the module when the kernel is updated.

Use the command:

    sudo make install

To uninstall, use:

    sudo make uninstall


If you just want to test it, without installing it, use these commands instead (DKMS is
not needed in this case):

    make
    sudo rmmod hid-wiimote # unload current hid-wiimote module
    sudo insmod ./hid-wiimote.ko


## Udev rules

The script [99-wiimote.rules](99-wiimote.rules) is installed automatically to
`/etc/udev/rules.d`. It forces most devices to have global read/write permissions
(`MODE="0666"`) and tags them to be game input devices (`ENV{ID_INPUT_JOYSTICK}="1"`) with
rules like this:

```
SUBSYSTEM=="input", ATTR{name}=="Nintendo Wii Remote", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
```

To inhibit a particular device (that is, stop it from generating input events), a
different rule is used:

```
SUBSYSTEM=="input", ATTR{name}=="Nintendo Wii Remote IR", ATTR{inhibited}="1"
```

This may be necessary for games that cannot handle accelerometer or gyro data
correctly. Some games may also keep reading from all available devices even when they're
not used, which increases power consumption.

**By default, accelerometer, gyro and IR inputs are all inhibited.** This will cause the
least amount of headaches. Edit `/etc/udev/rules.d/99-wiimote.rules` if you want to enable
one of these devices; changes to the udev rules will take effect next time the device is
connected.

You can use the `evemu-record` command from the `evemu` package to test if a device is
working as intended.
