;#include "tn10def.inc"
#include "m328Pdef.inc"

.cseg
.org 0
  rjmp  reset
.org INT0addr
  rjmp  ir_interrupt

#include "uart.asm"

delay:
    clr             r0
    clr             r1
delay0:
    dec             r0
    brne    delay0
    dec             r1
    brne    delay0
    dec             r16
    brne    delay0
    ret

delay_fast:
  nop
  nop
  dec   r16
  brne  delay_fast
  ret



; Receive IR packet
ir_interrupt:
  cli

  push  r16
  push  r17
  push  r18
  push  r19

time_pulse:
  ; 1.193ms is a long pulse
  lds   r16, TCNT1L
  lds   r17, TCNT1H
time_pulse_wait:
  sbis  PIND, PD2
  rjmp time_pulse_wait

  lds   r18, TCNT1L
  lds   r19, TCNT1H

  sub   r18, r16
  sbc   r19, r17
ir_interrupt_start:
  mov   r16, r18
  rcall uart_tx
ir_interrupt_done:

  pop   r19
  pop   r18
  pop   r17
  pop   r16

  sei

  reti

; Execution starts here
reset:
  sbi   DDRB, PB5

  ; INT0 triggered on falling edge
  ldi   r16, 1 << ISC01
  sts   EICRA, r16

  ; Enable INT0
  ldi   r16, 1 << INT0
  out   EIMSK, r16

  ; Enable TIMER1 with 1024 divider (15625/s at 16MHz)
  ldi   r16, 0x5
  sts   TCCR1B, r16

  sei

  rcall uart_init
loop:
  cbi   PORTB, PB5

  ldi   r16, 64 
	rcall delay

  sbi   PORTB, PB5

  ldi   r16, 64
	rcall delay

  rjmp	loop

