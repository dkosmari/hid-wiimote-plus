hid-wiimote-plus
================

This is a modification of the built-in Linux kernel module for Nintendo Wii remotes. It's
a drop-in replacement for the original module.


How is it different from the original Linux driver?
---------------------------------------------------

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

Battery charge reporting has been slightly improved.

Memory allocations are now managed by the device node; this ensures all memory is
deallocated when the device disconnects.



Installation
------------

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


Permission issues
-----------------

The script [99-wiimote.rules](99-wiimote.rules) is installed automatically to
`/etc/udev/rules.d`. If that script is not present, or conflicts with other scripts, you
may end up with devices missing the `ID_INPUT_JOYSTICK` tag, or with wrong permissions.

A simple way to test if the device is accessible is to use the `evemu` package; run either
`evemu-describe` or `evemu-record`, and see if it can access your devices. If a device
only appears when you run these commands with root/sudo permissions, that means you need
to tweak the udev rule.
