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
; r1 = pspan
;-----------------------------------------------------------------------------

#ifdef __MRISC32_HARD_FLOAT__

    .p2align    5
    .global     D_DrawSpans8
    .type       D_DrawSpans8, @function

D_DrawSpans8:
    ; Store callee saved registers on the stack.
    ; Also allocate space on the stack for local variables (register spill).
    add     sp, sp, #-68
    stw     lr, sp, #12
    stw     fp, sp, #16
    stw     tp, sp, #20
    stw     r26, sp, #24
    stw     r25, sp, #28
    stw     r24, sp, #32
    stw     r23, sp, #36
    stw     r22, sp, #40
    stw     r21, sp, #44
    stw     r20, sp, #48
    stw     r19, sp, #52
    stw     r18, sp, #56
    stw     r17, sp, #60
    stw     r16, sp, #64

    ; Load hot global variables into registers.
    addpchi r2, #cacheblock@pchi
    ldw     r2, r2, #cacheblock+4@pclo      ; r2 = pbase (unsigned char *)
    addpchi r3, #d_viewbuffer@pchi
    ldw     r3, r3, #d_viewbuffer+4@pclo    ; r3 = d_viewbuffer (byte *)
    addpchi r4, #screenwidth@pchi
    ldw     r4, r4, #screenwidth+4@pclo     ; r4 = screenwidth (int)
    addpchi r5, #d_sdivzstepu@pchi
    ldw     r5, r5, #d_sdivzstepu+4@pclo    ; r5 = d_sdivzstepu (float)
    addpchi r6, #d_tdivzstepu@pchi
    ldw     r6, r6, #d_tdivzstepu+4@pclo    ; r6 = d_tdivzstepu (float)
    addpchi r7, #d_zistepu@pchi
    ldw     r7, r7, #d_zistepu+4@pclo       ; r7 = d_zistepu (float)
    addpchi r8, #sadjust@pchi
    ldw     r8, r8, #sadjust+4@pclo         ; r8 = sadjust (fixed16_t)
    addpchi r9, #tadjust@pchi
    ldw     r9, r9, #tadjust+4@pclo         ; r9 = tadjust (fixed16_t)
    addpchi r10, #bbextents@pchi
    ldw     r10, r10, #bbextents+4@pclo     ; r10 = bbextents (fixed16_t)
    addpchi r11, #bbextentt@pchi
    ldw     r11, r11, #bbextentt+4@pclo     ; r11 = bbextentt (fixed16_t)
    addpchi r12, #cachewidth@pchi
    ldw     r12, r12, #cachewidth+4@pclo    ; r12 = cachewidth (int)
    addpchi r26, #d_sdivzstepv@pchi
    ldw     r26, r26, #d_sdivzstepv+4@pclo  ; r26 = d_sdivzstepv (float)

    ; Pre-calculate 8.0 * x (and store on the stack since we're out of regs).
    ldi     lr, #0x41000000             ; 8.0
    fmul    r13, r7, lr
    fmul    r14, r6, lr
    fmul    r15, r5, lr
    stw     r13, sp, #0                 ; 8.0 * d_zistepu
    stw     r14, sp, #4                 ; 8.0 * d_tdivzstepu
    stw     r15, sp, #8                 ; 8.0 * d_sdivzstepu

    ; Pre-load constants.
    ldi     tp, #0x47800000             ; tp = 65536.0

    ; Outer loop: Loop over spans.
1:
    ; pdest = (unsigned char *)&viewbuffer[(screenwidth * pspan->v) + pspan->u]
    ; NOTE: Schedule instructions to avoid stalls.
    ldw     r13, r1, #espan_t_v         ; r13 = pspan->v (int)
    ldw     r14, r1, #espan_t_u         ; r14 = pspan->u (int)
    mul     r15, r13, r4
    itof    r13, r13, z                 ; dv = (float)pspan->v
    ldw     r16, r1, #espan_t_count     ; r16 = count (int)
    add     r15, r15, r14
    itof    r14, r14, z                 ; du = (float)pspan->u
    ldea    r15, r3, r15                ; r15 = pdest

    ; Calculate the initial s/z, t/z, 1/z, s, and t and clamp.
    ; sdivz = d_sdivzorigin + dv*d_sdivzstepv + du*d_sdivzstepu
    ; tdivz = d_tdivzorigin + dv*d_tdivzstepv + du*d_tdivzstepu
    ; zi = d_ziorigin + dv*d_zistepv + du*d_zistepu
    ; NOTE: Schedule instructions to avoid stalls.
    fmul    r20, r14, r5
    fmul    r17, r13, r26
    addpchi lr, #d_tdivzstepv@pchi
    ldw     lr, lr, #d_tdivzstepv+4@pclo
    fmul    r21, r14, r6
    fmul    r18, r13, lr
    addpchi lr, #d_zistepv@pchi
    ldw     lr, lr, #d_zistepv+4@pclo
    fmul    r22, r14, r7
    fmul    r19, r13, lr
    fadd    r17, r17, r20
    fadd    r18, r18, r21
    addpchi lr, #d_sdivzorigin@pchi
    ldw     lr, lr, #d_sdivzorigin+4@pclo
    fadd    r19, r19, r22
    fadd    r17, r17, lr                ; r17 = sdivz (float)
    addpchi lr, #d_tdivzorigin@pchi
    ldw     lr, lr, #d_tdivzorigin+4@pclo
    addpchi r20, #d_ziorigin@pchi
    ldw     r20, r20, #d_ziorigin+4@pclo
    fadd    r18, r18, lr                ; r18 = tdivz (float)
    fadd    r19, r19, r20               ; r19 = zi (float)

    ; Invert zi and prescale to 16.16 fixed-point
    fdiv    r20, tp, r19                ; r20 = z = (float)0x10000 / zi

    ; s = clamp((int)(sdivz * z) + sadjust, 0, bbextents)
    ; t = clamp((int)(tdivz * z) + tadjust, 0, bbextentt)
    fmul    r21, r17, r20
    fmul    r22, r18, r20
    ftoi    r21, r21, z
    ftoi    r22, r22, z
    add     r21, r21, r8
    max     r21, r21, #0
    min     r21, r21, r10               ; r21 = s
    add     r22, r22, r9
    max     r22, r22, #0
    min     r22, r22, r11               ; r22 = t

    ; Inner loop: Loop over pixels, up to 8 pixels per iteration.
2:
    minu    vl, r16, #8                 ; vl = spancount = min(count, 8)
    sub     r16, r16, vl                ; count -= spancount

    ; Calculate s and t steps.
    bz      r16, 3f

    ; spancount is 8, so calculate s/z, t/z, zi->fixed s and t at far end of
    ; span, and calculate s and t steps across span by shifting.
    ldw     r23, sp, #0                 ; 8.0 * d_zistepu
    ldw     r24, sp, #4                 ; 8.0 * d_tdivzstepu
    ldw     r25, sp, #8                 ; 8.0 * d_sdivzstepu
    fadd    r19, r19, r23               ; zi += 8.0 * d_zistepu
    fadd    r18, r18, r24               ; tdivz += 8.0 * d_tdivzstepu
    fadd    r17, r17, r25               ; sdivz += 8.0 * d_sdivzstepu
    fdiv    r20, tp, r19                ; r20 = z = (float)0x10000 / zi

    ; snext = clamp((int)(sdivz * z) + sadjust, 8, bbextents)
    ; tnext = clamp((int)(tdivz * z) + tadjust, 8, bbextentt)
    fmul    r23, r17, r20
    fmul    r24, r18, r20
    ftoi    r23, r23, z
    ftoi    r24, r24, z
    add     r23, r23, r8
    max     r23, r23, #8
    min     r23, r23, r10               ; r23 = snext
    add     r24, r24, r9
    max     r24, r24, #8
    min     r24, r24, r11               ; r24 = tnext

    ; sstep = (snext - s) >> 3
    sub     r25, r23, r21
    asr     r25, r25, #3                ; r25 = sstep

    ; tstep = (tnext - t) >> 3
    sub     lr, r24, r22
    asr     lr, lr, #3                  ; lr = tstep

4:
#ifdef __MRISC32_VECTOR_OPS__
    ldea    v1, r21, r25                ; v1[k] = s + sstep * k
    ldea    v2, r22, lr                 ; v2[k] = t + tstep * k
    lsr     v1, v1, #16                 ; v1[k] = v1[k] >> 16
    lsr     v2, v2, #16                 ; v2[k] = v2[k] >> 16
    mul     v2, v2, r12                 ; v2[k] = v2[k] * cachewidth
    add     v1, v1, v2                  ; v1[k] = v1[k] + v2[k]
    ldub    v1, r2, v1                  ; v1[k] = pbase[v1[k]]
    stb     v1, r15, #1                 ; pdest[k] = v1[k]
    ldea    r15, r15, vl                ; pdest += spancount
#else
#error "Support for non-vectorized operation not implemented yet"
#endif

    mov     r21, r23                    ; s = snext
    mov     r22, r24                    ; t = tnext

    bnz     r16, 2b                     ; while (count > 0)

    ldw     r1, r1, #espan_t_pnext      ; pspan = pspan->pnext
    bnz     r1, 1b                      ; while (pspan != NULL)

    ; Restore callee saved registers from the stack.
    ldw     lr, sp, #12
    ldw     fp, sp, #16
    ldw     tp, sp, #20
    ldw     r26, sp, #24
    ldw     r25, sp, #28
    ldw     r24, sp, #32
    ldw     r23, sp, #36
    ldw     r22, sp, #40
    ldw     r21, sp, #44
    ldw     r20, sp, #48
    ldw     r19, sp, #52
    ldw     r18, sp, #56
    ldw     r17, sp, #60
    ldw     r16, sp, #64
    add     sp, sp, #68
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

    fmul    r23, r7, lr
    fmul    r24, r6, lr
    fmul    r25, r5, lr
    fadd    r19, r19, r23               ; zi += (spancount - 1) * d_zistepu
    fadd    r18, r18, r24               ; tdivz += (spancount - 1) * d_tdivzstepu
    fadd    r17, r17, r25               ; sdivz += (spancount - 1) * d_sdivzstepu
    fdiv    r20, tp, r19                ; r20 = z = (float)0x10000 / zi

    ; snext = clamp((int)(sdivz * z) + sadjust, 8, bbextents)
    ; tnext = clamp((int)(tdivz * z) + tadjust, 8, bbextentt)
    fmul    r23, r17, r20
    fmul    r24, r18, r20
    ftoi    r23, r23, z
    ftoi    r24, r24, z
    add     r23, r23, r8
    max     r23, r23, #8
    min     r23, r23, r10               ; r23 = snext
    add     r24, r24, r9
    max     r24, r24, #8
    min     r24, r24, r11               ; r24 = tnext

    ; sstep = (snext - s) / (spancount - 1)
    sub     r25, r23, r21
    div     r25, r25, fp                ; r25 = sstep

    ; tstep = (tnext - t) / (spancount - 1)
    sub     lr, r24, r22
    div     lr, lr, fp                  ; lr = tstep

    b       4b

    .size   D_DrawSpans8, .-D_DrawSpans8

#endif  /* __MRISC32_HARD_FLOAT__ */


;-----------------------------------------------------------------------------
; void D_DrawZSpans (espan_t *pspan)
;
; r1 = pspan
;-----------------------------------------------------------------------------

#ifdef __MRISC32_HARD_FLOAT__

    .p2align    5
    .global     D_DrawZSpans
    .type       D_DrawZSpans, @function

D_DrawZSpans:
    addpchi r2, #d_pzbuffer@pchi
    ldw     r2, r2, #d_pzbuffer+4@pclo  ; r2 = d_pzbuffer (short *)
    addpchi r3, #d_zwidth@pchi
    ldw     r3, r3, #d_zwidth+4@pclo    ; r3 = d_zwidth (unsigned int)
    addpchi r4, #d_ziorigin@pchi
    ldw     r4, r4, #d_ziorigin+4@pclo  ; r4 = d_ziorigin (float)
    addpchi r5, #d_zistepu@pchi
    ldw     r5, r5, #d_zistepu+4@pclo   ; r5 = d_zistepu (float)
    addpchi r6, #d_zistepv@pchi
    ldw     r6, r6, #d_zistepv+4@pclo   ; r6 = d_zistepv (float)

    ldi     r7, #31                     ; r7 = 31 (used for ftoi)
    ftoir   r12, r5, r7                 ; r12 = izistep = (int)(d_zistepu * 2^31)

    ; Outer loop.
1:
    ; Calculate the initial 1/z
    ldw     r11, r1, #espan_t_v         ; r11 = pspan->v (int)
    ldw     r10, r1, #espan_t_u         ; r10 = pspan->u (int)
    mul     r8, r11, r3
    itof    r11, r11, z                 ; r11 = dv = (float)pspan->v
    ldw     r9, r1, #espan_t_count      ; r9 = count (int)
    add     r8, r8, r10
    itof    r10, r10, z                 ; r10 = du = (float)pspan->u
    ldea    r8, r2, r8*2                ; r8 = pdest (short*)
    fmul    r11, r11, r6
    fmul    r10, r10, r5
    fadd    r10, r10, r11
    fadd    r10, r10, r4                ; r10 = zi = d_ziorigin + dv*d_zistepv + du*d_zistepu
    ftoir   r10, r10, r7                ; r10 = izi = (int)(zi * 2^31)

    ; Handle un-aligned head.
    and     r11, r8, #2
    bz      r11, 2f
    lsr     r11, r10, #16               ; r11 = (short)(izi >> 16)
    add     r10, r10, r12               ; izi += izistep
    add     r8, r8, #2                  ; pdest++
    add     r9, r9, #-1                 ; count--
    sth     r11, r8, #-2                ; *pdest = r11

2:
    lsr     r13, r9, #1                 ; r13 = doublecount
    bz      r13, 4f

    ; Inner loop (two 1/z values per iteration).
3:
    add     r14, r10, r12               ; izi += izistep
#ifdef __MRISC32_PACKED_OPS__
    packhi  r11, r14, r10
#else
    shuf    r15, r14, #0b0011010100100  ; r15 = r14 & 0xffff0000
    lsr     r11, r10, #16
    or      r11, r15, r11
#endif
    add     r10, r14, r12               ; izi += izistep
    add     r13, r13, #-1               ; doublecount--
    stw     r11, r8, #0                 ; *(int*)pdest = (r14 & 0xffff0000 | (r10 >> 16))
    add     r8, r8, #4                  ; pdest += 2
    bnz     r13, 3b

4:
    ldw     r1, r1, #espan_t_pnext      ; pspan = pspan->pnext

    ; Handle un-aligned tail.
    and     r9, r9, #1
    bz      r9, 5f
    lsr     r11, r10, #16               ; r11 = (short)(izi >> 16)
    sth     r11, r8, #0                 ; *pdest = r11

5:
    ; while (pspan != NULL)
    bnz     r1, 1b

    ret

    .size   D_DrawZSpans, .-D_DrawZSpans

#endif  /* __MRISC32_HARD_FLOAT__ */

#endif  /* __MRISC32__ */

