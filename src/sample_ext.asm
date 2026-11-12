; Extended PCM feeder routines. Keep the v0.47 MODE/DIR algorithm while
; preserving v0.48's selected-tone DAC latch in shadow C ($90/$B0/$D0).
.BANK 1 SLOT 1
.SECTION "SampleFeedExtended" FREE

smp_pcm_feed:
  ld a, (smp_speed)
  or a
  jr z, spm_1x
  dec a
  jr z, spm_2x
  dec a
  jp z, spm_4x
  ld a, (smp_hold)
  xor 1
  ld (smp_hold), a
  ret nz
  jr spm_1x

spm_1x:
  ld a, (smp_reverse)
  or a
  jr nz, spm_rev_1x
  bit 0, c
  jr nz, spm_fwd_low
  call spm_fwd_check
  jr nc, spm_fwd_fetch
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_start)
spm_fwd_fetch:
  ld a, (hl)
  inc hl
  ld b, a
  rrca
  rrca
  rrca
  rrca
  and $0F
  or c
  out (PSG_PORT), a
  inc c
  ret
spm_fwd_low:
  ld a, b
  and $0F
  dec c
  or c
  out (PSG_PORT), a
  ret

spm_rev_1x:
  bit 0, c
  jr nz, spm_rev_high
  call spm_rev_check
  jr nc, spm_rev_fetch
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_last)
spm_rev_fetch:
  ld a, (hl)
  ld b, a
  and $0F
  or c
  out (PSG_PORT), a
  inc c
  ret
spm_rev_high:
  ld a, b
  rrca
  rrca
  rrca
  rrca
  and $0F
  dec c
  or c
  out (PSG_PORT), a
  dec hl
  ret

spm_2x:
  ld a, (smp_reverse)
  or a
  jr nz, spm_rev_2x
  call spm_fwd_check
  jr nc, spm_fwd_2x_go
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_start)
spm_fwd_2x_go:
  ld a, (hl)
  inc hl
  rrca
  rrca
  rrca
  rrca
  and $0F
  or c
  out (PSG_PORT), a
  ret
spm_rev_2x:
  call spm_rev_check
  jr nc, spm_rev_2x_go
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_last)
spm_rev_2x_go:
  ld a, (hl)
  dec hl
  and $0F
  or c
  out (PSG_PORT), a
  ret

spm_4x:
  ld a, (smp_reverse)
  or a
  jr nz, spm_rev_4x
  call spm_fwd_check
  jr nc, spm_fwd_4x_go
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_start)
spm_fwd_4x_go:
  ld a, (hl)
  inc hl
  inc hl
  rrca
  rrca
  rrca
  rrca
  and $0F
  or c
  out (PSG_PORT), a
  ret
spm_rev_4x:
  call spm_rev_check
  jr nc, spm_rev_4x_go
  ld a, (smp_loop)
  or a
  jp z, spm_end
  ld hl, (smp_last)
spm_rev_4x_go:
  ld a, (hl)
  dec hl
  dec hl
  and $0F
  or c
  out (PSG_PORT), a
  ret

; Carry set means the current byte pointer has reached/passed its bound.
; Forward: HL >= DE(end). Reverse: HL < DE(start).
spm_fwd_check:
  ld a, h
  cp d
  jr c, spm_fc_ok
  jr nz, spm_fc_end
  ld a, l
  cp e
  jr c, spm_fc_ok
spm_fc_end:
  scf
  ret
spm_fc_ok:
  or a
  ret

spm_rev_check:
  ld a, h
  cp d
  jr c, spm_rc_end
  jr nz, spm_rc_ok
  ld a, l
  cp e
  jr c, spm_rc_end
spm_rc_ok:
  or a
  ret
spm_rc_end:
  scf
  ret

spm_end:
  ld a, (smp_dac_ch)
  rrca
  rrca
  rrca
  or $9F
  out (PSG_PORT), a
  xor a
  ld (smp_active), a
  ret

.ENDS
