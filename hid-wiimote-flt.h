/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * HID driver for Nintendo Wii / Wii U peripherals
 * Copyright (c) 2025 Daniel K. O.
 */
#ifndef __HID_WIIMOTE_FLT_H
#define __HID_WIIMOTE_FLT_H

int wiimod_remap_flt(int x,
		     int src_lo, int src_hi,
		     int dst_lo, int dst_hi);

int wiimod_battery_core_get_uvolts_raw_flt(int raw);
int wiimod_battery_bboard_get_uvolts_raw_flt(int raw);

int wiimod_bboard_correct_weight_flt(int w, int temp, int ref_temp);

#endif
