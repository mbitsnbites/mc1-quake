/*
Copyright (C) 1996-1997 Id Software, Inc.
Copyright (C) 2021 Marcus Geelnard

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
// sys_null.h -- null system driver to aid porting efforts

#include "quakedef.h"
#include "errno.h"

#include <stdint.h>
#include <sys/time.h>

//----------------------------------------------------------------------------
// Begin MC1 definitions (should probably be in a header file somewhere)
//----------------------------------------------------------------------------

// MC1 MMIO.
// clang-format off
#define CLKCNTLO    0
#define CLKCNTHI    4
#define CPUCLK      8
#define VRAMSIZE    12
#define XRAMSIZE    16
#define VIDWIDTH    20
#define VIDHEIGHT   24
#define VIDFPS      28
#define VIDFRAMENO  32
#define VIDY        36
#define SWITCHES    40
#define BUTTONS     44
#define KEYPTR      48
#define MOUSEPOS    52
#define MOUSEBTNS   56
// clang-format on

#define GET_MMIO(reg) \
	(*(volatile unsigned *)(&((volatile byte *)0xc0000000)[reg]))
#define GET_KEYBUF(ptr) \
	((volatile unsigned *)(((volatile byte *)0xc0000080)))[ptr]
#define KEYBUF_SIZE 16

// MC1 keyboard scancodes.
// clang-format off
#define KB_A                0x01c
#define KB_B                0x032
#define KB_C                0x021
#define KB_D                0x023
#define KB_E                0x024
#define KB_F                0x02b
#define KB_G                0x034
#define KB_H                0x033
#define KB_I                0x043
#define KB_J                0x03b
#define KB_K                0x042
#define KB_L                0x04b
#define KB_M                0x03a
#define KB_N                0x031
#define KB_O                0x044
#define KB_P                0x04d
#define KB_Q                0x015
#define KB_R                0x02d
#define KB_S                0x01b
#define KB_T                0x02c
#define KB_U                0x03c
#define KB_V                0x02a
#define KB_W                0x01d
#define KB_X                0x022
#define KB_Y                0x035
#define KB_Z                0x01a
#define KB_0                0x045
#define KB_1                0x016
#define KB_2                0x01e
#define KB_3                0x026
#define KB_4                0x025
#define KB_5                0x02e
#define KB_6                0x036
#define KB_7                0x03d
#define KB_8                0x03e
#define KB_9                0x046

#define KB_SPACE            0x029
#define KB_BACKSPACE        0x066
#define KB_TAB              0x00d
#define KB_LSHIFT           0x012
#define KB_LCTRL            0x014
#define KB_LALT             0x011
#define KB_LMETA            0x11f
#define KB_RSHIFT           0x059
#define KB_RCTRL            0x114
#define KB_RALT             0x111
#define KB_RMETA            0x127
#define KB_ENTER            0x05a
#define KB_ESC              0x076
#define KB_F1               0x005
#define KB_F2               0x006
#define KB_F3               0x004
#define KB_F4               0x00c
#define KB_F5               0x003
#define KB_F6               0x00b
#define KB_F7               0x083
#define KB_F8               0x00a
#define KB_F9               0x001
#define KB_F10              0x009
#define KB_F11              0x078
#define KB_F12              0x007

#define KB_INSERT           0x170
#define KB_HOME             0x16c
#define KB_DEL              0x171
#define KB_END              0x169
#define KB_PGUP             0x17d
#define KB_PGDN             0x17a
#define KB_UP               0x175
#define KB_LEFT             0x16b
#define KB_DOWN             0x172
#define KB_RIGHT            0x174

#define KB_KP_0             0x070
#define KB_KP_1             0x069
#define KB_KP_2             0x072
#define KB_KP_3             0x07a
#define KB_KP_4             0x06b
#define KB_KP_5             0x073
#define KB_KP_6             0x074
#define KB_KP_7             0x06c
#define KB_KP_8             0x075
#define KB_KP_9             0x07d
#define KB_KP_PERIOD        0x071
#define KB_KP_PLUS          0x079
#define KB_KP_MINUS         0x07b
#define KB_KP_MUL           0x07c
#define KB_KP_DIV           0x06d
#define KB_KP_ENTER         0x06e

#define KB_ACPI_POWER       0x137
#define KB_ACPI_SLEEP       0x13f
#define KB_ACPI_WAKE        0x15e

#define KB_MM_NEXT_TRACK    0x14d
#define KB_MM_PREV_TRACK    0x115
#define KB_MM_STOP          0x13b
#define KB_MM_PLAY_PAUSE    0x134
#define KB_MM_MUTE          0x123
#define KB_MM_VOL_UP        0x132
#define KB_MM_VOL_DOWN      0x121
#define KB_MM_MEDIA_SEL     0x150
#define KB_MM_EMAIL         0x148
#define KB_MM_CALCULATOR    0x12b
#define KB_MM_MY_COMPUTER   0x140

#define KB_WWW_SEARCH       0x110
#define KB_WWW_HOME         0x13a
#define KB_WWW_BACK         0x138
#define KB_WWW_FOWRARD      0x130
#define KB_WWW_STOP         0x128
#define KB_WWW_REFRESH      0x120
#define KB_WWW_FAVORITES    0x118
// clang-format on

//----------------------------------------------------------------------------
// End MC1 definitions
//----------------------------------------------------------------------------

qboolean isDedicated;

static int Sys_TranslateKey (unsigned keycode)
{
	// clang-format off
    switch (keycode)
    {
        case KB_SPACE:         return K_SPACE;
        case KB_LEFT:          return K_LEFTARROW;
        case KB_RIGHT:         return K_RIGHTARROW;
        case KB_DOWN:          return K_DOWNARROW;
        case KB_UP:            return K_UPARROW;
        case KB_ESC:           return K_ESCAPE;
        case KB_ENTER:
        case KB_KP_ENTER:      return K_ENTER;
        case KB_TAB:           return K_TAB;
        case KB_F1:            return K_F1;
        case KB_F2:            return K_F2;
        case KB_F3:            return K_F3;
        case KB_F4:            return K_F4;
        case KB_F5:            return K_F5;
        case KB_F6:            return K_F6;
        case KB_F7:            return K_F7;
        case KB_F8:            return K_F8;
        case KB_F9:            return K_F9;
        case KB_F10:           return K_F10;
        case KB_F11:           return K_F11;
        case KB_F12:           return K_F12;
        case KB_DEL:
        case KB_BACKSPACE:     return K_BACKSPACE;
        case KB_MM_PLAY_PAUSE: return K_PAUSE;
        case KB_LSHIFT:
        case KB_RSHIFT:        return K_SHIFT;
        case KB_LCTRL:
        case KB_RCTRL:         return K_CTRL;
        case KB_LALT:
        case KB_LMETA:
        case KB_RALT:
        case KB_RMETA:         return K_ALT;

        case KB_KP_PLUS:       return '+';
        case KB_KP_MINUS:      return '-';

        case KB_A:             return 'a';
        case KB_B:             return 'b';
        case KB_C:             return 'c';
        case KB_D:             return 'd';
        case KB_E:             return 'e';
        case KB_F:             return 'f';
        case KB_G:             return 'g';
        case KB_H:             return 'h';
        case KB_I:             return 'i';
        case KB_J:             return 'j';
        case KB_K:             return 'k';
        case KB_L:             return 'l';
        case KB_M:             return 'm';
        case KB_N:             return 'n';
        case KB_O:             return 'o';
        case KB_P:             return 'p';
        case KB_Q:             return 'q';
        case KB_R:             return 'r';
        case KB_S:             return 's';
        case KB_T:             return 't';
        case KB_U:             return 'u';
        case KB_V:             return 'v';
        case KB_W:             return 'w';
        case KB_X:             return 'x';
        case KB_Y:             return 'y';
        case KB_Z:             return 'z';
        case KB_0:             return '0';
        case KB_1:             return '1';
        case KB_2:             return '2';
        case KB_3:             return '3';
        case KB_4:             return '4';
        case KB_5:             return '5';
        case KB_6:             return '6';
        case KB_7:             return '7';
        case KB_8:             return '8';
        case KB_9:             return '9';

        default:
            return 0;
    }
	// clang-format on
}

static unsigned s_keyptr;

static qboolean Sys_PollKeyEvent (void)
{
	unsigned keyptr, keycode;
	int quake_key;

	// Check if we have any new keycode from the keyboard.
	keyptr = GET_MMIO (KEYPTR);
	if (s_keyptr == keyptr)
		return false;

	// Get the next keycode.
	++s_keyptr;
	keycode = GET_KEYBUF (s_keyptr % KEYBUF_SIZE);

	// Translate the MC1 keycode to a Quake keycode.
	quake_key = Sys_TranslateKey (keycode & 0x1ff);
	if (quake_key != 0)
	{
		Key_Event (quake_key, (keycode & 0x80000000) ? true : false);
	}
	return true;
}

/*
===============================================================================

FILE IO

===============================================================================
*/

#define MAX_HANDLES 10
FILE *sys_handles[MAX_HANDLES];

int findhandle (void)
{
	int i;

	for (i = 1; i < MAX_HANDLES; i++)
		if (!sys_handles[i])
			return i;
	Sys_Error ("out of handles");
	return -1;
}

/*
================
filelength
================
*/
int filelength (FILE *f)
{
	int pos;
	int end;

	pos = ftell (f);
	fseek (f, 0, SEEK_END);
	end = ftell (f);
	fseek (f, pos, SEEK_SET);

	return end;
}

int Sys_FileOpenRead (char *path, int *hndl)
{
	FILE *f;
	int i;

	i = findhandle ();

	f = fopen (path, "rb");
	if (!f)
	{
		*hndl = -1;
		return -1;
	}
	sys_handles[i] = f;
	*hndl = i;

	return filelength (f);
}

int Sys_FileOpenWrite (char *path)
{
	FILE *f;
	int i;

	i = findhandle ();

	f = fopen (path, "wb");
	if (!f)
		Sys_Error ("Error opening %s: %s", path, strerror (errno));
	sys_handles[i] = f;

	return i;
}

void Sys_FileClose (int handle)
{
	fclose (sys_handles[handle]);
	sys_handles[handle] = NULL;
}

void Sys_FileSeek (int handle, int position)
{
	fseek (sys_handles[handle], position, SEEK_SET);
}

int Sys_FileRead (int handle, void *dest, int count)
{
	return fread (dest, 1, count, sys_handles[handle]);
}

int Sys_FileWrite (int handle, void *data, int count)
{
	return fwrite (data, 1, count, sys_handles[handle]);
}

int Sys_FileTime (char *path)
{
	FILE *f;

	f = fopen (path, "rb");
	if (f)
	{
		fclose (f);
		return 1;
	}

	return -1;
}

void Sys_mkdir (char *path)
{
}

/*
===============================================================================

SYSTEM IO

===============================================================================
*/

void Sys_MakeCodeWriteable (unsigned long startaddr, unsigned long length)
{
}

void Sys_Error (char *error, ...)
{
	va_list argptr;

	printf ("Sys_Error: ");
	va_start (argptr, error);
	vprintf (error, argptr);
	va_end (argptr);
	printf ("\n");

	exit (1);
}

void Sys_Printf (char *fmt, ...)
{
	va_list argptr;

	va_start (argptr, fmt);
	vprintf (fmt, argptr);
	va_end (argptr);
}

void Sys_Quit (void)
{
	exit (0);
}

double Sys_FloatTime (void)
{
#if 1
	// MRISC32 simulator timing: Use gettimeofday().
	static qboolean s_first = true;
	static struct timeval s_t0;
	struct timeval t;

	if (s_first)
	{
		gettimeofday (&s_t0, NULL);
		s_first = false;
	}
	gettimeofday (&t, NULL);
	return (double)(t.tv_sec - s_t0.tv_sec) +
		   0.000001 * (double)(t.tv_usec - s_t0.tv_usec);
#else
	// MC1 timing: Use CLKCNTHI:CLKCNTLO MMIO registers directly.
	static qboolean s_first = true;
	static double s_inv_clk;
	uint32_t hi_old, hi, lo;
	uint64_t cycles;
	double t;

	// Get 1 / cycles per s.
	if (s_first)
	{
		s_inv_clk = 1.0 / (double)GET_MMIO (CPUCLK);
		s_first = false;
	}

	// Get number of CPU cycles (64-bit number).
	hi = GET_MMIO (CLKCNTHI);
	do
	{
		hi_old = hi;
		lo = GET_MMIO (CLKCNTLO);
		hi = GET_MMIO (CLKCNTHI);
	} while (hi != hi_old);

	cycles = (((uint64_t)hi) << 32) | (uint64_t)lo;
	return s_inv_clk * (double)cycles;
#endif
}

char *Sys_ConsoleInput (void)
{
	return NULL;
}

void Sys_Sleep (void)
{
}

void Sys_SendKeyEvents (void)
{
	while (Sys_PollKeyEvent ())
		;
}

void Sys_HighFPPrecision (void)
{
}

void Sys_LowFPPrecision (void)
{
}

//=============================================================================

void main (int argc, char **argv)
{
	static quakeparms_t parms;
	double oldtime, newtime, time;

	parms.memsize = 8 * 1024 * 1024;
	parms.membase = malloc (parms.memsize);
	parms.basedir = ".";

	COM_InitArgv (argc, argv);

	parms.argc = com_argc;
	parms.argv = com_argv;

	printf ("Host_Init\n");
	Host_Init (&parms);

	s_keyptr = GET_MMIO (KEYPTR);
	oldtime = Sys_FloatTime () - 0.1;
	while (1)
	{
		// find time spent rendering last frame
		newtime = Sys_FloatTime ();
		time = newtime - oldtime;

		if (time > sys_ticrate.value * 2)
			oldtime = newtime;
		else
			oldtime += time;

		Host_Frame (time);
	}
}
