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

  push   r16
  push   r17
  push   r18

  ldi   r16, 'i'
  rcall uart_tx
  ;sbi   PIND, PD1

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

