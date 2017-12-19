;#include "tn10def.inc"
#include "m328Pdef.inc"

.define MY_ID 0x15

.define PIN_RX PD2

.define PULSE_LONG  (0x1F-1)
.define PULSE_MED   (0x11-1)
.define PULSE_SHORT (0x06-1)

.define PACKET_BIT_COUNT 8

.macro measure_pulse
  lds   r16, TCNT1L
  lds   r17, TCNT1H
time_pulse_start_wait_%:
  sbis  PIND, PIN_RX
  rjmp time_pulse_start_wait_%

  ; Calculate pulse length

  lds   r18, TCNT1L
  lds   r19, TCNT1H

  ; r18:r19 is pulse length in clock1 ticks
  sub   r18, r16
  sbc   r19, r17
.endm

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
  push  r20
  push  r21

time_pulse:
  ; Measures length of first pulse
  ; and skip if it is not a (long) start pulse
  ; 1.193ms (0x1F timer diff) is a long pulse

  measure_pulse

  ; Exit interrupt if this is not a long pulse

  ldi   r16, low(PULSE_LONG)
  ldi   r17, high(PULSE_LONG)

  cp r18, r16
  cpc r19, r17
  brlt ir_interrupt_done

  ; It's a start pulse!
ir_interrupt_start:
  clr   r20 ; For the received bits
  ldi   r21, PACKET_BIT_COUNT
ir_interrupt_read_bit:
  sbic  PIND, PIN_RX
  rjmp  ir_interrupt_read_bit

  measure_pulse

  ldi   r16, low(PULSE_MED)
  ldi   r17, high(PULSE_MED)

  cp r18, r16
  cpc r19, r17
  brlt ir_interrupt_read_bit_0

ir_interrupt_read_bit_1:
  sec
  rjmp  ir_interrupt_read_finish
ir_interrupt_read_bit_0:
  clc
ir_interrupt_read_finish:
  ror   r20 ; Shift received bit in

  dec   r21
  brne  ir_interrupt_read_bit

  ; We are done reading the packet! Received value in r20

  ; Does the ID match?
  andi  r20, 0x1F ; Mask the ID (lower 5 bits)
  cpi   r20, MY_ID
  brne  ir_interrupt_done

  ldi   r16, 'i'
  rcall uart_tx
  ldi   r16, 't'
  rcall uart_tx
  ldi   r16, ' '
  rcall uart_tx
  ldi   r16, 'm'
  rcall uart_tx
  ldi   r16, 'e'
  rcall uart_tx
  ldi   r16, 10
  rcall uart_tx

ir_interrupt_done:

  pop   r21
  pop   r20
  pop   r19
  pop   r18
  pop   r17
  pop   r16

  sei

  reti

; Execution starts here
reset:
  sbi   DDRB, PB5

  ; Setup Z for buffering received data
  ldi   ZL, low(SRAM_START)
  ldi   ZH, high(SRAM_START)

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
  rjmp	loop

