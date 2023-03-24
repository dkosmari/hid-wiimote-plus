hid-wiimote-plus
================

This is a modification of the built-in Linux kernel module for Nintendo Wii remotes. It's
a drop-in replacement for the original module.


How is it different?
--------------------

1. The mapping from Wii remotes (and accessories) buttons and axes was modified to respect
   the Linux kernel conventions, and behave like gamepads, instead of a mixture of gamepad
   and keyboard. For convenience, [gamepad.rst](gamepad.rst) from the Linux docs is
   included here.

   - D-pad buttons are now mapped to `BTN_DPAD_*` events, instead of keyboard arrow keys.

   - Buttons `+/Start` and `-/Select` are now mapped to `BTN_START` and `BTN_SELECT`.

   - Face/action buttons are now mapped to east, south, north, west buttons.

2. Better battery status reporting, to make it interact more nicely with desktop
   environments.

3. Memory allocation is done in the module's scope, so it's guaranteed to be released when
   the module unloads.

4. Accelerometer and gyro devices register proper metadata
   (`INPUT_PROP_ACCELEROMETER` and correct units.)

5. Sticks (Nunchuk and Classic Controller) don't invert the Y axis anymore. Positive
   values mean "down."

6. Classic Controller Pro no longer reports analog shoulder buttons (`L/R`), only
   the Classic Controller (not Pro) has them. Range for analog shoulder buttons
   has been corrected from `[-30, +30]` to `[0, +60]`.

7. Balance Board reports its sensors as `HAT0X`, `HAT1X`, `HAT2X`, `HAT3X`; that is,
   four 1-D axes instead of two 2-D axes.

8. No more emulation of an analog stick through the d-pad.


How to install?
---------------

You will need the kernel development headers in your system. Additionally, you will need
the DKMS package; it allows for easy install and uninstall, and will automatically rebuild
the module when the kernel is updated.

Use the commands:

    sudo make install

To uninstall, use:

    sudo make uninstall


If you just want to test it, without installing it, use these commands instead:

    make build
    sudo rmmod hid-wiimote
    sudo insmod ./hid-wiimote.ko
