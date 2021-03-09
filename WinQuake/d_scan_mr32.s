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

#ifdef __MRISC32__

#include "asm_draw.h"

; d_scan_mr32.s
; MRISC32 assembler implementations of span drawing functions.

;-----------------------------------------------------------------------------
; void D_DrawZSpans (espan_t *pspan)
;
; s1 = pspan
;-----------------------------------------------------------------------------

#ifdef __MRISC32_HARD_FLOAT__

    .p2align    5
    .global     D_DrawZSpans
    .type       D_DrawZSpans, @function

D_DrawZSpans:
    addpchi s2, #d_pzbuffer@pchi
    ldw     s2, s2, #d_pzbuffer+4@pclo  ; s2 = d_pzbuffer (short *)
    addpchi s3, #d_zwidth@pchi
    ldw     s3, s3, #d_zwidth+4@pclo    ; s3 = d_zwidth (unsigned int)
    addpchi s4, #d_ziorigin@pchi
    ldw     s4, s4, #d_ziorigin+4@pclo  ; s4 = d_ziorigin (float)
    addpchi s5, #d_zistepu@pchi
    ldw     s5, s5, #d_zistepu+4@pclo   ; s5 = d_zistepu (float)
    addpchi s6, #d_zistepv@pchi
    ldw     s6, s6, #d_zistepv+4@pclo   ; s6 = d_zistepv (float)

    ldi     s7, #31                     ; s7 = 31 (used for ftoi)
    ftoir   s12, s5, s7                 ; s12 = izistep = (int)(d_zistepu * 2^31)

    ; Outer loop.
1:
    ; Calculate the initial 1/z
    ldw     s11, s1, #espan_t_v         ; s11 = pspan->v (int)
    ldw     s10, s1, #espan_t_u         ; s10 = pspan->u (int)
    mul     s8, s11, s3
    itof    s11, s11, z                 ; s11 = dv = (float)pspan->v
    ldw     s9, s1, #espan_t_count      ; s9 = count (int)
    add     s8, s8, s10
    itof    s10, s10, z                 ; s10 = du = (float)pspan->u
    ldea    s8, s2, s8*2                ; s8 = pdest (short*)
    fmul    s11, s11, s6
    fmul    s10, s10, s5
    fadd    s10, s10, s11
    fadd    s10, s10, s4                ; s10 = zi = d_ziorigin + dv*d_zistepv + du*d_zistepu
    ftoir   s10, s10, s7                ; s10 = izi = (int)(zi * 2^31)

    ; Handle un-aligned head.
    and     s11, s8, #2
    bz      s11, 2f
    lsr     s11, s10, #16               ; s11 = (short)(izi >> 16)
    add     s10, s10, s12               ; izi += izistep
    add     s8, s8, #2                  ; pdest++
    add     s9, s9, #-1                 ; count--
    sth     s11, s8, #-2                ; *pdest = s11

2:
    lsr     s13, s9, #1                 ; s13 = doublecount
    bz      s13, 4f

    ; Inner loop (two 1/z values per iteration).
3:
    add     s14, s10, s12               ; izi += izistep
#ifdef __MRISC32_PACKED_OPS__
    packhi  s11, s14, s10
#else
    shuf    s15, s14, #0b0011010100100  ; s15 = s14 & 0xffff0000
    lsr     s11, s10, #16
    or      s11, s15, s11
#endif
    add     s10, s14, s12               ; izi += izistep
    add     s13, s13, #-1               ; doublecount--
    stw     s11, s8, #0                 ; *(int*)pdest = (s14 & 0xffff0000 | (s10 >> 16))
    add     s8, s8, #4                  ; pdest += 2
    bnz     s13, 3b

4:
    ldw     s1, s1, #espan_t_pnext      ; pspan = pspan->pnext

    ; Handle un-aligned tail.
    and     s9, s9, #1
    bz      s9, 5f
    lsr     s11, s10, #16               ; s11 = (short)(izi >> 16)
    sth     s11, s8, #0                 ; *pdest = s11

5:
    ; while (pspan != NULL)
    bnz     s1, 1b

    ret

    .size   D_DrawZSpans, .-D_DrawZSpans

#endif  /* __MRISC32_HARD_FLOAT__ */

#endif  /* __MRISC32__ */

