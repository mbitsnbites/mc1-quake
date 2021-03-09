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
; void D_DrawSpans8 (espan_t *pspan)
;
; s1 = pspan
;-----------------------------------------------------------------------------

#ifdef __MRISC32_HARD_FLOAT__

    .p2align    5
    .global     D_DrawSpans8
    .type       D_DrawSpans8, @function

D_DrawSpans8:
    ; Store callee saved registers on the stack.
    ; Also allocate space on the stack for local variables (register spill).
    add     sp, sp, #-64
    stw     lr, sp, #12
    stw     tp, sp, #16
    stw     fp, sp, #20
    stw     s25, sp, #24
    stw     s24, sp, #28
    stw     s23, sp, #32
    stw     s22, sp, #36
    stw     s21, sp, #40
    stw     s20, sp, #44
    stw     s19, sp, #48
    stw     s18, sp, #52
    stw     s17, sp, #56
    stw     s16, sp, #60

    ; Load hot global variables into registers.
    addpchi s2, #cacheblock@pchi
    ldw     s2, s2, #cacheblock+4@pclo      ; s2 = pbase (unsigned char *)
    addpchi s3, #d_viewbuffer@pchi
    ldw     s3, s3, #d_viewbuffer+4@pclo    ; s3 = d_viewbuffer (byte *)
    addpchi s4, #screenwidth@pchi
    ldw     s4, s4, #screenwidth+4@pclo     ; s4 = screenwidth (int)
    addpchi s5, #d_sdivzstepu@pchi
    ldw     s5, s5, #d_sdivzstepu+4@pclo    ; s5 = d_sdivzstepu (float)
    addpchi s6, #d_tdivzstepu@pchi
    ldw     s6, s6, #d_tdivzstepu+4@pclo    ; s6 = d_tdivzstepu (float)
    addpchi s7, #d_zistepu@pchi
    ldw     s7, s7, #d_zistepu+4@pclo       ; s7 = d_zistepu (float)
    addpchi s8, #sadjust@pchi
    ldw     s8, s8, #sadjust+4@pclo         ; s8 = sadjust (fixed16_t)
    addpchi s9, #tadjust@pchi
    ldw     s9, s9, #tadjust+4@pclo         ; s9 = tadjust (fixed16_t)
    addpchi s10, #bbextents@pchi
    ldw     s10, s10, #bbextents+4@pclo     ; s10 = bbextents (fixed16_t)
    addpchi s11, #bbextentt@pchi
    ldw     s11, s11, #bbextentt+4@pclo     ; s11 = bbextentt (fixed16_t)
    addpchi s12, #cachewidth@pchi
    ldw     s12, s12, #cachewidth+4@pclo    ; s12 = cachewidth (int)

    ; Pre-calculate 8.0 * x (and store on the stack since we're out of regs).
    ldi     lr, #0x41000000             ; 8.0
    fmul    s13, s7, lr
    fmul    s14, s6, lr
    fmul    s15, s5, lr
    stw     s13, sp, #0                 ; 8.0 * d_zistepu
    stw     s14, sp, #4                 ; 8.0 * d_tdivzstepu
    stw     s15, sp, #8                 ; 8.0 * d_sdivzstepu

    ; Pre-load constants.
    ldi     tp, #0x47800000             ; tp = 65536.0

    ; Outer loop: Loop over spans.
1:
    ; pdest = (unsigned char *)&viewbuffer[(screenwidth * pspan->v) + pspan->u]
    ; NOTE: Schedule instructions to avoid stalls.
    ldw     s13, s1, #espan_t_v         ; s13 = pspan->v (int)
    ldw     s14, s1, #espan_t_u         ; s14 = pspan->u (int)
    mul     s15, s13, s4
    itof    s13, s13, z                 ; dv = (float)pspan->v
    ldw     s16, s1, #espan_t_count     ; s16 = count (int)
    add     s15, s15, s14
    itof    s14, s14, z                 ; du = (float)pspan->u
    ldea    s15, s3, s15                ; s15 = pdest

    ; Calculate the initial s/z, t/z, 1/z, s, and t and clamp.
    ; sdivz = d_sdivzorigin + dv*d_sdivzstepv + du*d_sdivzstepu
    ; tdivz = d_tdivzorigin + dv*d_tdivzstepv + du*d_tdivzstepu
    ; zi = d_ziorigin + dv*d_zistepv + du*d_zistepu
    ; NOTE: Schedule instructions to avoid stalls.
    addpchi lr, #d_sdivzstepv@pchi
    ldw     lr, lr, #d_sdivzstepv+4@pclo
    fmul    s20, s14, s5
    fmul    s17, s13, lr
    addpchi lr, #d_tdivzstepv@pchi
    ldw     lr, lr, #d_tdivzstepv+4@pclo
    fmul    s21, s14, s6
    fmul    s18, s13, lr
    addpchi lr, #d_zistepv@pchi
    ldw     lr, lr, #d_zistepv+4@pclo
    fmul    s22, s14, s7
    fmul    s19, s13, lr
    fadd    s17, s17, s20
    fadd    s18, s18, s21
    addpchi lr, #d_sdivzorigin@pchi
    ldw     lr, lr, #d_sdivzorigin+4@pclo
    fadd    s19, s19, s22
    fadd    s17, s17, lr                ; s17 = sdivz (float)
    addpchi lr, #d_tdivzorigin@pchi
    ldw     lr, lr, #d_tdivzorigin+4@pclo
    addpchi s20, #d_ziorigin@pchi
    ldw     s20, s20, #d_ziorigin+4@pclo
    fadd    s18, s18, lr                ; s18 = tdivz (float)
    fadd    s19, s19, s20               ; s19 = zi (float)

    ; Invert zi and prescale to 16.16 fixed-point
    fdiv    s20, tp, s19                ; s20 = z = (float)0x10000 / zi

    ; s = clamp((int)(sdivz * z) + sadjust, 0, bbextents)
    ; t = clamp((int)(tdivz * z) + tadjust, 0, bbextentt)
    fmul    s21, s17, s20
    fmul    s22, s18, s20
    ftoi    s21, s21, z
    ftoi    s22, s22, z
    add     s21, s21, s8
    max     s21, s21, #0
    min     s21, s21, s10               ; s21 = s
    add     s22, s22, s9
    max     s22, s22, #0
    min     s22, s22, s11               ; s22 = t

    ; Inner loop: Loop over pixels, up to 8 pixels per iteration.
2:
    minu    vl, s16, #8                 ; vl = spancount = min(count, 8)
    sub     s16, s16, vl                ; count -= spancount

    ; Calculate s and t steps.
    bz      s16, 3f

    ; spancount is 8, so calculate s/z, t/z, zi->fixed s and t at far end of
    ; span, and calculate s and t steps across span by shifting.
    ldw     s23, sp, #0                 ; 8.0 * d_zistepu
    ldw     s24, sp, #4                 ; 8.0 * d_tdivzstepu
    ldw     s25, sp, #8                 ; 8.0 * d_sdivzstepu
    fadd    s19, s19, s23               ; zi += 8.0 * d_zistepu
    fadd    s18, s18, s24               ; tdivz += 8.0 * d_tdivzstepu
    fadd    s17, s17, s25               ; sdivz += 8.0 * d_sdivzstepu
    fdiv    s20, tp, s19                ; s20 = z = (float)0x10000 / zi

    ; snext = clamp((int)(sdivz * z) + sadjust, 8, bbextents)
    ; tnext = clamp((int)(tdivz * z) + tadjust, 8, bbextentt)
    fmul    s23, s17, s20
    fmul    s24, s18, s20
    ftoi    s23, s23, z
    ftoi    s24, s24, z
    add     s23, s23, s8
    max     s23, s23, #8
    min     s23, s23, s10               ; s23 = snext
    add     s24, s24, s9
    max     s24, s24, #8
    min     s24, s24, s11               ; s24 = tnext

    ; sstep = (snext - s) >> 3
    sub     s25, s23, s21
    asr     s25, s25, #3                ; s25 = sstep

    ; tstep = (tnext - t) >> 3
    sub     lr, s24, s22
    asr     lr, lr, #3                  ; lr = tstep

4:
#ifdef __MRISC32_VECTOR_OPS__
    ldea    v1, s21, s25                ; v1[k] = s + sstep * k
    ldea    v2, s22, lr                 ; v2[k] = t + tstep * k
    lsr     v1, v1, #16                 ; v1[k] = v1[k] >> 16
    lsr     v2, v2, #16                 ; v2[k] = v2[k] >> 16
    mul     v2, v2, s12                 ; v2[k] = v2[k] * cachewidth
    add     v1, v1, v2                  ; v1[k] = v1[k] + v2[k]
    ldub    v1, s2, v1                  ; v1[k] = pbase[v1[k]]
    stb     v1, s15, #1                 ; pdest[k] = v1[k]
    ldea    s15, s15, vl                ; pdest += spancount
#else
#error "Support for non-vectorized operation not implemented yet"
#endif

    mov     s21, s23                    ; s = snext
    mov     s22, s24                    ; t = tnext

    bnz     s16, 2b                     ; while (count > 0)

    ldw     s1, s1, #espan_t_pnext      ; pspan = pspan->pnext
    bnz     s1, 1b                      ; while (pspan != NULL)

    ; Restore callee saved registers from the stack.
    ldw     lr, sp, #12
    ldw     tp, sp, #16
    ldw     fp, sp, #20
    ldw     s25, sp, #24
    ldw     s24, sp, #28
    ldw     s23, sp, #32
    ldw     s22, sp, #36
    ldw     s21, sp, #40
    ldw     s20, sp, #44
    ldw     s19, sp, #48
    ldw     s18, sp, #52
    ldw     s17, sp, #56
    ldw     s16, sp, #60
    add     sp, sp, #64
    ret

3:
    ; spancount is <8, so calculate s/z, t/z, zi->fixed s and t at last pixel
    ; in span (so can't step off polygon), clamp, calculate s and t steps
    ; across span by division, biasing steps low so we don't run off the
    ; texture.
    add     fp, vl, #-1                 ; fp = spancount - 1
    itof    lr, fp, z                   ; (float)(spancount - 1)

    bz      fp, 4b                      ; Early-out if spancount == 1
                                        ; (and hide some of the itof latency)

    fmul    s23, s7, lr
    fmul    s24, s6, lr
    fmul    s25, s5, lr
    fadd    s19, s19, s23               ; zi += (spancount - 1) * d_zistepu
    fadd    s18, s18, s24               ; tdivz += (spancount - 1) * d_tdivzstepu
    fadd    s17, s17, s25               ; sdivz += (spancount - 1) * d_sdivzstepu
    fdiv    s20, tp, s19                ; s20 = z = (float)0x10000 / zi

    ; snext = clamp((int)(sdivz * z) + sadjust, 8, bbextents)
    ; tnext = clamp((int)(tdivz * z) + tadjust, 8, bbextentt)
    fmul    s23, s17, s20
    fmul    s24, s18, s20
    ftoi    s23, s23, z
    ftoi    s24, s24, z
    add     s23, s23, s8
    max     s23, s23, #8
    min     s23, s23, s10               ; s23 = snext
    add     s24, s24, s9
    max     s24, s24, #8
    min     s24, s24, s11               ; s24 = tnext

    ; sstep = (snext - s) / (spancount - 1)
    sub     s25, s23, s21
    div     s25, s25, fp                ; s25 = sstep

    ; tstep = (tnext - t) / (spancount - 1)
    sub     lr, s24, s22
    div     lr, lr, fp                  ; lr = tstep

    b       4b

    .size   D_DrawSpans8, .-D_DrawSpans8

#endif  /* __MRISC32_HARD_FLOAT__ */


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

