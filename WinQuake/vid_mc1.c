/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
// vid_null.c -- null video driver to aid porting efforts

#include "quakedef.h"
#include "d_local.h"

#include <string.h>
#include <mr32intrin.h>

#define BASEWIDTH 320
#define BASEHEIGHT 200

// We assume that the Quake binary is loaded into XRAM (0x80000000...), or
// into the "ROM" (0x00000000...) for the simulator, and that it has complete
// ownership of VRAM (0x40000000...). Hence we just hard-code the video
// addresses.
#define VRAM_BASE 0x40000100
#define VCP_SIZE (4 * (16 + BASEHEIGHT * 2))
#define PAL_SIZE (4 * (256 + 1))
static byte *const VRAM_VCP = (byte *)VRAM_BASE;
static byte *const VRAM_PAL = (byte *)(VRAM_BASE + VCP_SIZE);
static byte *const VRAM_FB = (byte *)(VRAM_BASE + VCP_SIZE + PAL_SIZE);

extern viddef_t vid;  // global video state

byte vid_buffer[BASEWIDTH * BASEHEIGHT];
short zbuffer[BASEWIDTH * BASEHEIGHT];
byte surfcache[256 * 1024];

unsigned short d_8to16table[256];
unsigned d_8to24table[256];

static void VID_CreateVCP (byte *vcp)
{
	// TODO(m): Implement me!
	(void)vcp;
}

void VID_SetPalette (unsigned char *palette)
{
	unsigned *dst = (unsigned *)VRAM_PAL;
	const unsigned a = 255;
	for (int i = 0; i < 256; ++i)
	{
		unsigned r = (unsigned)palette[i * 3];
		unsigned g = (unsigned)palette[i * 3 + 1];
		unsigned b = (unsigned)palette[i * 3 + 2];
#ifdef __MRISC32_PACKED_OPS__
		dst[i] = _mr32_pack_h (_mr32_pack (a, g), _mr32_pack (b, r));
#else
		dst[i] = (a << 24) | (b << 16) | (g << 8) | r;
#endif
	}
}

void VID_ShiftPalette (unsigned char *palette)
{
	VID_SetPalette (palette);
}

void VID_Init (unsigned char *palette)
{
	VID_CreateVCP (VRAM_VCP);

	printf (
		"VID_Init: Framebuffer @ 0x%08x (%d)\n"
		"          Palette     @ 0x%08x (%d)\n",
		(unsigned)VRAM_FB,
		(unsigned)VRAM_FB,
		(unsigned)VRAM_PAL,
		(unsigned)VRAM_PAL);

	vid.maxwarpwidth = vid.width = vid.conwidth = BASEWIDTH;
	vid.maxwarpheight = vid.height = vid.conheight = BASEHEIGHT;
	vid.aspect = 1.0;
	vid.numpages = 1;
	vid.colormap = host_colormap;
	vid.fullbright = 256 - LittleLong (*((int *)vid.colormap + 2048));
	vid.buffer = vid.conbuffer = vid_buffer;
	vid.rowbytes = vid.conrowbytes = BASEWIDTH;

	d_pzbuffer = zbuffer;
	D_InitCaches (surfcache, sizeof (surfcache));
}

void VID_Shutdown (void)
{
}

void VID_Update (vrect_t *rects)
{
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
#pragma GCC diagnostic ignored "-Wstringop-overflow"
#endif
	memcpy (VRAM_FB, vid.buffer, BASEWIDTH * BASEHEIGHT);
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
}

/*
================
D_BeginDirectRect
================
*/
void D_BeginDirectRect (int x, int y, byte *pbitmap, int width, int height)
{
}

/*
================
D_EndDirectRect
================
*/
void D_EndDirectRect (int x, int y, int width, int height)
{
}
