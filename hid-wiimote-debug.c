// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Debug support for HID Nintendo Wii / Wii U peripherals
 * Copyright (c) 2011-2013 David Herrmann <dh.herrmann@gmail.com>
 * Copyright (c) 2018-2023 Daniel K. O.
 */

/*
 */

#include <linux/debugfs.h>
#include <linux/module.h>
#include <linux/seq_file.h>
#include <linux/spinlock.h>
#include <linux/uaccess.h>
#include "hid-wiimote.h"

#ifdef CONFIG_DEBUG_FS

struct wiimote_debug {
	struct wiimote_data *wdata;
	struct dentry *eeprom;
	struct dentry *registers;
	struct dentry *drm;
};

static ssize_t wiidebug_memory_read(struct file *f,
				    char __user *ubuf,
				    size_t size,
				    loff_t *offset,
				    bool is_eeprom)
{
	struct wiimote_debug *dbg = f->private_data;
	struct wiimote_data *wdata = dbg->wdata;
	unsigned long flags;
	ssize_t ret;
	char kbuf[16];

	if (size == 0)
		return -EINVAL;
	if (*offset > 0xffffff)
		return 0;
	if (size > 16)
		size = 16;

	ret = wiimote_cmd_acquire(wdata);
	if (ret)
		return ret;
	{
		spin_lock_irqsave(&wdata->state.lock, flags);
		{
			wdata->state.cmd_read_size = size;
			wdata->state.cmd_read_buf = kbuf;
			wiimote_cmd_set(wdata, WIIPROTO_REQ_RMEM, *offset & 0xffff);
			wiiproto_req_rmem(wdata, is_eeprom, *offset, size);
		}
		spin_unlock_irqrestore(&wdata->state.lock, flags);

		ret = wiimote_cmd_wait(wdata);
		if (!ret)
			size = wdata->state.cmd_read_size;

		spin_lock_irqsave(&wdata->state.lock, flags);
		{
			wdata->state.cmd_read_buf = NULL;
		}
		spin_unlock_irqrestore(&wdata->state.lock, flags);
	}
	wiimote_cmd_release(wdata);

	if (ret)
		return ret;
	else if (size == 0)
		return -EIO;

	if (copy_to_user(ubuf, kbuf, size))
		return -EFAULT;

	*offset += size;
	ret = size;

	return ret;
}

/* TODO: implement write */

static loff_t wiidebug_eeprom_llseek(struct file *f,
				     loff_t offset,
				     int whence)
{
	return fixed_size_llseek(f, offset, whence, 0x1700);
}

static ssize_t wiidebug_eeprom_read(struct file *f,
				    char __user *ubuf,
				    size_t size,
				    loff_t *offset)
{
	return wiidebug_memory_read(f, ubuf, size, offset, true);
}

static const struct file_operations wiidebug_eeprom_fops = {
	.owner = THIS_MODULE,
	.llseek = wiidebug_eeprom_llseek,
	.read = wiidebug_eeprom_read,
	.open = simple_open,
};

static loff_t wiidebug_registers_llseek(struct file *f,
					loff_t offset,
					int whence)
{
	loff_t result;
	result = fixed_size_llseek(f, offset, whence, 0x1000000);
	return result;
}

static ssize_t wiidebug_registers_read(struct file *f,
				      char __user *ubuf,
				      size_t size,
				      loff_t *offset)
{
	return wiidebug_memory_read(f, ubuf, size, offset, false);
}

static const struct file_operations wiidebug_registers_fops = {
	.owner = THIS_MODULE,
	.llseek = wiidebug_registers_llseek,
	.read = wiidebug_registers_read,
	.open = simple_open,
};

static const char *wiidebug_drmmap[] = {
	[WIIPROTO_REQ_NULL] = "NULL",
	[WIIPROTO_REQ_DRM_K] = "K",
	[WIIPROTO_REQ_DRM_KA] = "KA",
	[WIIPROTO_REQ_DRM_KE] = "KE",
	[WIIPROTO_REQ_DRM_KAI] = "KAI",
	[WIIPROTO_REQ_DRM_KEE] = "KEE",
	[WIIPROTO_REQ_DRM_KAE] = "KAE",
	[WIIPROTO_REQ_DRM_KIE] = "KIE",
	[WIIPROTO_REQ_DRM_KAIE] = "KAIE",
	[WIIPROTO_REQ_DRM_E] = "E",
	[WIIPROTO_REQ_DRM_SKAI1] = "SKAI1",
	[WIIPROTO_REQ_DRM_SKAI2] = "SKAI2",
	[WIIPROTO_REQ_MAX] = NULL
};

static int wiidebug_drm_show(struct seq_file *f, void *p)
{
	struct wiimote_debug *dbg = f->private;
	const char *str = NULL;
	unsigned long flags;
	__u8 drm;

	spin_lock_irqsave(&dbg->wdata->state.lock, flags);
	drm = dbg->wdata->state.drm;
	spin_unlock_irqrestore(&dbg->wdata->state.lock, flags);

	if (drm < WIIPROTO_REQ_MAX)
		str = wiidebug_drmmap[drm];
	if (!str)
		str = "unknown";

	seq_printf(f, "%s\n", str);

	return 0;
}

static int wiidebug_drm_open(struct inode *i, struct file *f)
{
	return single_open(f, wiidebug_drm_show, i->i_private);
}

static ssize_t wiidebug_drm_write(struct file *f, const char __user *u,
				  size_t s, loff_t *off)
{
	struct seq_file *sf = f->private_data;
	struct wiimote_debug *dbg = sf->private;
	unsigned long flags;
	char buf[16];
	ssize_t len;
	int i;

	if (s == 0)
		return -EINVAL;

	len = min((size_t) 15, s);
	if (copy_from_user(buf, u, len))
		return -EFAULT;

	buf[len] = 0;

	for (i = 0; i < WIIPROTO_REQ_MAX; ++i) {
		if (!wiidebug_drmmap[i])
			continue;
		if (!strcasecmp(buf, wiidebug_drmmap[i]))
			break;
	}

	if (i == WIIPROTO_REQ_MAX)
		i = simple_strtoul(buf, NULL, 16);

	spin_lock_irqsave(&dbg->wdata->state.lock, flags);
	dbg->wdata->state.flags &= ~WIIPROTO_FLAG_DRM_LOCKED;
	wiiproto_req_drm(dbg->wdata, (__u8) i);
	if (i != WIIPROTO_REQ_NULL)
		dbg->wdata->state.flags |= WIIPROTO_FLAG_DRM_LOCKED;
	spin_unlock_irqrestore(&dbg->wdata->state.lock, flags);

	return len;
}

static const struct file_operations wiidebug_drm_fops = {
	.owner = THIS_MODULE,
	.open = wiidebug_drm_open,
	.read = seq_read,
	.llseek = seq_lseek,
	.write = wiidebug_drm_write,
	.release = single_release,
};

static void wiidebug_cleanup(struct wiimote_data *wdata,
			     struct wiimote_debug *dbg)
{
	if (dbg->drm)
		debugfs_remove(dbg->drm);
	if (dbg->registers)
		debugfs_remove(dbg->registers);
	if (dbg->eeprom)
		debugfs_remove(dbg->eeprom);
	devm_kfree(&wdata->hdev->dev, dbg);
}

int wiidebug_init(struct wiimote_data *wdata)
{
	struct wiimote_debug *dbg;
	unsigned long flags;

	dbg = devm_kzalloc(&wdata->hdev->dev, sizeof(*dbg), GFP_KERNEL);
	if (!dbg)
		return -ENOMEM;

	dbg->wdata = wdata;

	dbg->eeprom = debugfs_create_file("eeprom",
					  S_IRUSR,
					  dbg->wdata->hdev->debug_dir,
					  dbg,
					  &wiidebug_eeprom_fops);
	if (!dbg->eeprom) {
		wiidebug_cleanup(wdata, dbg);
		return -ENOMEM;
	}

	dbg->registers = debugfs_create_file("registers",
					     S_IRUSR,
					     dbg->wdata->hdev->debug_dir,
					     dbg,
					     &wiidebug_registers_fops);
	if (!dbg->registers) {
		wiidebug_cleanup(wdata, dbg);
		return -ENOMEM;
	}

	dbg->drm = debugfs_create_file("drm",
				       S_IRUSR,
				       dbg->wdata->hdev->debug_dir,
				       dbg,
				       &wiidebug_drm_fops);
	if (!dbg->drm) {
		wiidebug_cleanup(wdata, dbg);
		return -ENOMEM;
	}

	spin_lock_irqsave(&wdata->state.lock, flags);
	wdata->debug = dbg;
	spin_unlock_irqrestore(&wdata->state.lock, flags);

	return 0;
}

void wiidebug_deinit(struct wiimote_data *wdata)
{
	struct wiimote_debug *dbg = wdata->debug;
	unsigned long flags;

	if (!dbg)
		return;

	spin_lock_irqsave(&wdata->state.lock, flags);
	wdata->debug = NULL;
	spin_unlock_irqrestore(&wdata->state.lock, flags);

	wiidebug_cleanup(wdata, dbg);
}

#else /* CONFIG_DEBUG_FS */

int wiidebug_init(struct wiimote_data *wdata) { return 0; }

void wiidebug_deinit(struct wiimote_data *wdata) { }

#endif


/* Local Variables:    */
/* indent-tabs-mode: t */
/* c-basic-offset: 8   */
/* End:                */
