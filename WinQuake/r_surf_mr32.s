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

; r_surf_mr32.s
; MRISC32 assembler implementations of surface block drawing.

;-----------------------------------------------------------------------------
; We describe the R_DrawSurfaceBlock8 function for each mip level as a macro.
;
;  count   = Loop count   (16, 8, 4 or 2)
;  l2count = log2(count)  (4, 3, 2 or 1)
;-----------------------------------------------------------------------------

.macro R_DrawSurfaceBlock8 count, l2count
    ; Get the outer loop counter (and skip to the end if zero).
    addpchi s10, #r_numvblocks@pchi
    ldw     s10, s10, #r_numvblocks+4@pclo  ; s10 = v (= r_numvblocks)
    bz      s10, 2$

    ; Save callee saved registers.
    add     sp, sp, #-4
    stw     vl, sp, #0

    ; Pre-load global variables into registers.
    addpchi s1, #sourcetstep@pchi
    ldw     s1, s1, #sourcetstep+4@pclo     ; s1 = sourcetstep
    addpchi s2, #surfrowbytes@pchi
    ldw     s2, s2, #surfrowbytes+4@pclo    ; s2 = surfrowbytes
    addpchi s3, #r_lightwidth@pchi
    ldw     s3, s3, #r_lightwidth+4@pclo    ; s3 = r_lightwidth
    addpchi s4, #r_sourcemax@pchi
    ldw     s4, s4, #r_sourcemax+4@pclo     ; s4 = r_sourcemax
    addpchi s5, #r_stepback@pchi
    ldw     s5, s5, #r_stepback+4@pclo      ; s5 = r_stepback
    addpchi s6, #r_lightptr@pchi
    ldw     s6, s6, #r_lightptr+4@pclo      ; s6 = r_lightptr
    addpchi s7, #vid+4@pchi
    ldw     s7, s7, #vid+4+4@pclo           ; s7 = vid.colormap (vid+4)
    addpchi s8, #pbasesource@pchi
    ldw     s8, s8, #pbasesource+4@pclo     ; s8 = pbasesource
    addpchi s9, #prowdestbase@pchi
    ldw     s9, s9, #prowdestbase+4@pclo    ; s9 = prowdestbase

    ; Set up vector operation.
    ldi     vl, #\count         ; We use the same VL for all iterations.
    ldi     s15, #0x0000ff00
    or      v3, vz, s15         ; v3 = select mask

    ; Outer loop.
1$:
    ; Set up light step & boundaries for this iteration.
    ldw     s11, s6, #0         ; s11 = lightleft = r_lightptr[0]
    ldw     s12, s6, #4         ; s12 = lightright = r_lightptr[1]
    ldea    s6, s6, s3 * 4      ; r_lightptr += r_lightwidth
    ldw     s13, s6, #0
    sub     s13, s13, s11
    asr     s13, s13, #\l2count ; s13 = lightleftstep = (r_lightptr[0] - lightleft) >> l2count
    ldw     s14, s6, #4
    sub     s14, s14, s12
    asr     s14, s14, #\l2count ; s14 = lightrightstep = (r_lightptr[1] - lightright) >> l2count

    ; Unroll the inner loop.
    .rept   \count
        sub     s15, s12, s11
        asr     s15, s15, #\l2count ; s15 = lightstep = (lightright - lightleft) >> l2count
        ldub    v1, s8, #1          ; v1 = pbasesource[b]
        ldea    v2, s11, s15        ; v2 = lightleft + lightstep*b
        sel.231 v1, v3, v2          ; v1 = (v2 & 0xff00) | v1
        ldub    v1, s7, v1          ; v1 = vid.colormap[(v2 & 0xff00) | v1]
        stb     v1, s9, #1          ; prowdestbase[b] = v1
        ldea    s8, s8, s1          ; pbasesource += sourcetstep
        add     s11, s11, s13       ; lightleft += lightleftstep
        add     s12, s12, s14       ; lightright += lightrightstep
        ldea    s9, s9, s2          ; prowdestbase += surfrowbytes
    .endr

    sle     s15, s4, s8         ; pbasesource >= r_sourcemax?
    bns     s15, 1f
    sub     s8, s8, s5          ; pbasesource -= r_stepback
1:
    add     s10, s10, #-1       ; v--
    bnz     s10, 1$

    ; Store the final value of r_lightptr.
    addpchi s1, #r_lightptr@pchi
    stw     s6, s1, #r_lightptr+4@pclo

    ; Restore callee saved registers.
    ldw     vl, sp, #0
    add     sp, sp, #4

2$:
    ret
.endm


	.text

;-----------------------------------------------------------------------------
; void R_DrawSurfaceBlock8_mip0 (void)
;-----------------------------------------------------------------------------

    .p2align    5
    .global     R_DrawSurfaceBlock8_mip0
    .type       R_DrawSurfaceBlock8_mip0, @function

R_DrawSurfaceBlock8_mip0:
    R_DrawSurfaceBlock8 16, 4

    .size   R_DrawSurfaceBlock8_mip0, .-R_DrawSurfaceBlock8_mip0


;-----------------------------------------------------------------------------
; void R_DrawSurfaceBlock8_mip1 (void)
;-----------------------------------------------------------------------------

    .p2align    5
    .global     R_DrawSurfaceBlock8_mip1
    .type       R_DrawSurfaceBlock8_mip1, @function

R_DrawSurfaceBlock8_mip1:
    R_DrawSurfaceBlock8 8, 3

    .size   R_DrawSurfaceBlock8_mip1, .-R_DrawSurfaceBlock8_mip1


;-----------------------------------------------------------------------------
; void R_DrawSurfaceBlock8_mip2 (void)
;-----------------------------------------------------------------------------

    .p2align    5
    .global     R_DrawSurfaceBlock8_mip2
    .type       R_DrawSurfaceBlock8_mip2, @function

R_DrawSurfaceBlock8_mip2:
    R_DrawSurfaceBlock8 4, 2

    .size   R_DrawSurfaceBlock8_mip2, .-R_DrawSurfaceBlock8_mip2


;-----------------------------------------------------------------------------
; void R_DrawSurfaceBlock8_mip3 (void)
;-----------------------------------------------------------------------------

    .p2align    5
    .global     R_DrawSurfaceBlock8_mip3
    .type       R_DrawSurfaceBlock8_mip3, @function

R_DrawSurfaceBlock8_mip3:
    R_DrawSurfaceBlock8 2, 1

    .size   R_DrawSurfaceBlock8_mip3, .-R_DrawSurfaceBlock8_mip3

