.define MY_ID 0x01
.define PLATFORM_ATTINY10 1

.ifdef PLATFORM_ATTINY10
#include "tn10def.inc"
#include "attiny10-pins.inc"
.define TIMERVAL_L TCNT0L
.define TIMERVAL_H TCNT0H
.elseif
#include "m328Pdef.inc"
#include "atmega328p-pins.inc"
.define TIMERVAL_L TCNT1L
.define TIMERVAL_H TCNT1H
.endif

.define PULSE_LONG  (0x1F-1)
.define PULSE_MED   (0x11-1)
.define PULSE_SHORT (0x06-1)

.define PACKET_BIT_COUNT 8

.define CMD_STOP          0
.define CMD_FORWARD_LEFT  1
.define CMD_FORWARD_RIGHT 2
.define CMD_REVERSE_LEFT  3

.macro measure_pulse
.ifdef PLATFORM_ATTINY10
  in    r16, TCNT0L
  in    r17, TCNT0H
.else
  lds   r16, TCNT1L
  lds   r17, TCNT1H
.endif
time_pulse_start_wait_%:
  sbis  PINPORT_RX, PIN_RX
  rjmp time_pulse_start_wait_%

  ; Calculate pulse length

.ifdef PLATFORM_ATTINY10
  in    r18, TCNT0L
  in    r19, TCNT0H
.else
  lds   r18, TCNT1L
  lds   r19, TCNT1H
.endif

  ; r18:r19 is pulse length in clock1 ticks
  sub   r18, r16
  sbc   r19, r17
.endm

.macro bug_stop
  cbi   DDR_MOTOR, PIN_FWD_L
  cbi   PORT_MOTOR, PIN_FWD_L

  cbi   DDR_MOTOR, PIN_FWD_R
  cbi   PORT_MOTOR, PIN_FWD_R

  cbi   DDR_MOTOR, PIN_REV_L
  cbi   PORT_MOTOR, PIN_REV_L
.endm

.macro bug_forward_left
  sbi   PORT_MOTOR, PIN_FWD_L
.endm

.macro bug_forward_right
  sbi   PORT_MOTOR, PIN_FWD_R
.endm

.macro bug_reverse_left
  cbi   PORT_MOTOR, PIN_FWD_L
  sbi   PORT_MOTOR, PIN_REV_L
.endm

.cseg
.org 0
  rjmp  reset
.org INT0addr
  rjmp  ir_interrupt

.ifndef PLATFORM_ATTINY10
;#include "uart.asm"
.endif

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
; NOTE: This code assumes everything happens in the interrupt handler below
; so register state is not saved (also 'cause ATTiny10s don't have the push instruction)
ir_interrupt:
  cli

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
  sbic  PINPORT_RX, PIN_RX
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

  ; We are done reading the packet! Received value in r21
  mov   r21, r20

  ; Does the ID match?
  andi  r20, 0x1F ; Mask the ID (lower 5 bits)
  cpi   r20, MY_ID
  brne  ir_interrupt_done

  mov   r20, r21
  andi  r20, 0xE0 ; Mask the command (upper 3 bits)
  cpi   r20, CMD_STOP << 5
  brne  ir_interrupt_check_fwd_l
  
  bug_stop

  rjmp ir_interrupt_done
ir_interrupt_check_fwd_l:
  cpi   r20, CMD_FORWARD_LEFT << 5
  brne ir_interrupt_check_fwd_r

  bug_forward_left

  rjmp ir_interrupt_done
ir_interrupt_check_fwd_r:
  cpi   r20, CMD_FORWARD_RIGHT << 5
  brne ir_interrupt_check_rev_l

  bug_forward_right

  rjmp ir_interrupt_done
ir_interrupt_check_rev_l:
  cpi   r20, CMD_REVERSE_LEFT << 5
  brne ir_interrupt_done

  bug_reverse_left

ir_interrupt_done:

  sei

  reti

; Execution starts here
reset:
  ; INT0 triggered on falling edge
  ldi   r16, 1 << ISC01
.ifdef PLATFORM_ATTINY10
  out   EICRA, r16
.else
  sts   EICRA, r16
.endif

  ; Enable INT0
  ldi   r16, 1 << INT0
  out   EIMSK, r16

  ; Enable TIMER1 with 1024 divider (15625/s at 16MHz)
  ldi   r16, 0x5
.ifdef PLATFORM_ATTINY10
  out   TCCR0B, r16
.else
  sts   TCCR1B, r16
.endif

  sei

.ifndef PLATFORM_ATTINY10
  ;rcall uart_init
.endif
loop:
  rjmp	loop

