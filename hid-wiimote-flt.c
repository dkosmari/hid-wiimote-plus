// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Device Modules for Nintendo Wii / Wii U HID Driver
 * Copyright (c) 2025 Daniel K. O.
 */

#include <linux/version.h>

#include "hid-wiimote-flt.h"

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 10, 0)

int wiimod_remap_flt(int x,
		     int src_lo, int src_hi,
		     int dst_lo, int dst_hi)
{
	int src_delta = src_hi - src_lo;
	int dst_delta = dst_hi - dst_lo;
	if (src_delta <= 0 || dst_delta <= 0)
		return 0;
	return dst_lo + dst_delta * (x - src_lo) / (double)src_delta;
}


int wiimod_battery_core_get_uvolts_flt(int raw)
{
	float m = 5221.92f;
	float b = 2154361.0f;
	return m * raw + b;
}

int wiimod_battery_bboard_get_uvolts_flt(int raw)
{
	float m = 40642.57f;
	float b = -76462.994f;
	return m * raw + b;
}

int wiimod_bboard_correct_weight_flt(int w, int temp, int ref_temp)
{
	/* Based on https://wiibrew.org/wiki/Wii_Balance_Board */
	/* Gravitational correction, ideally it should depend on global coordinates. */
	static const double a = 0.9990813732147217;
	/* Temperature correction. */
	static const double b = 0.007000000216066837;
	double c = 1.0 - b * (temp - ref_temp) / 10.0;
	return (int)(w * a * c);
}

#endif
