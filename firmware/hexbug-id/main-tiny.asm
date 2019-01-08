#include "tn10def.inc"
#include "attiny10-pins.inc"

.define MY_ID 24

;.define DEBUG_PRINT_CMD 1
;.define DEBUG_PRINT_PULSE_LEN 1
;.define DEBUG_PRINT_PACKETS 1
;.define DEBUG_PRINT_ID_MISMATCH 1

.define PULSE_LONG  (0x1F-5)
.define PULSE_MED   (0x08)
;.define PULSE_SHORT (0x06-1)

.define PACKET_BIT_COUNT 8

.define CMD_STOP          0
.define CMD_FORWARD_LEFT  1
.define CMD_FORWARD_RIGHT 2
.define CMD_REVERSE_LEFT  3

.macro measure_pulse
  in    r16, TCNT0L
  in    r17, TCNT0H
time_pulse_start_wait_%:
  sbis  PINPORT_RX, PIN_RX
  rjmp time_pulse_start_wait_%

  ; Calculate pulse length

  in    r18, TCNT0L
  in    r19, TCNT0H

  ; r18:r19 is pulse length in clock1 ticks
  sub   r18, r16
  sbc   r19, r17
.endm

.macro bug_stop
  cbi   PORT_MOTOR, PIN_FWD_L
  cbi   PORT_MOTOR, PIN_FWD_R
  cbi   PORT_MOTOR, PIN_REV_L
.endm

.macro bug_forward_left
  cbi   PORT_MOTOR, PIN_REV_L
  sbi   PORT_MOTOR, PIN_FWD_L
.endm

.macro bug_forward_right
  sbi   PORT_MOTOR, PIN_FWD_R
.endm

.macro bug_reverse_left
  cbi   PORT_MOTOR, PIN_FWD_L
  sbi   PORT_MOTOR, PIN_REV_L
.endm

; PROGRAM MEMORY STARTS HERE

.cseg
.org 0
  rjmp  reset
  rjmp  reset
  rjmp  ir_interrupt

delay:
    clr             r17
    clr             r18
delay0:
    dec             r17
    brne    delay0
    dec             r18
    brne    delay0
    dec             r16
    brne    delay0
    ret

; Receive IR packet
; NOTE: This code assumes everything happens in the interrupt handler below
; so register state is not saved (also 'cause ATTiny10s don't have the push instruction)
ir_interrupt:
  ; Exit interrupt if we are not here because of a falling edge
  sbic  PINB, PIN_RX
  reti

  cli

time_pulse:
  ; Measures length of first pulse
  ; and skip if it is not a (long) start pulse
  ; 1.193ms (0x1F timer diff) is a long pulse

  measure_pulse

.ifdef DEBUG_PRINT_PULSE_LEN
  ; FIXME
  mov   r16, r18
  rcall uart_tx
  rjmp  ir_interrupt_done
.endif

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

.ifdef DEBUG_PRINT_PACKETS
  ; FIXME
  mov   r16, r20
  rcall uart_tx
.endif

  ; Does the ID match?
  andi  r20, 0x1F ; Mask the ID (lower 5 bits)
  cpi   r20, MY_ID
  brne  ir_interrupt_not_me

  mov   r20, r21
  andi  r20, 0xE0 ; Mask the command (upper 3 bits)
  cpi   r20, CMD_STOP << 5
  brne  ir_interrupt_check_fwd_l
  
.ifdef  DEBUG_PRINT_CMD
  ldi   r16, 's'
  rcall uart_tx
.else
  bug_stop
.endif

  rjmp ir_interrupt_done
ir_interrupt_check_fwd_l:
  cpi   r20, CMD_FORWARD_LEFT << 5
  brne ir_interrupt_check_fwd_r

.ifdef  DEBUG_PRINT_CMD
  ldi   r16, 'l'
  rcall uart_tx
.else
  bug_forward_left
.endif

  rjmp ir_interrupt_done
ir_interrupt_check_fwd_r:
  cpi   r20, CMD_FORWARD_RIGHT << 5
  brne ir_interrupt_check_rev_l

.ifdef DEBUG_PRINT_CMD
  ldi   r16, 'r'
  rcall uart_tx
.else
  bug_forward_right
.endif

  rjmp ir_interrupt_done
ir_interrupt_check_rev_l:
  cpi   r20, CMD_REVERSE_LEFT << 5
  brne ir_interrupt_done

.ifdef DEBUG_PRINT_CMD
  ldi   r16, 'b'
  rcall uart_tx
.else
  bug_reverse_left
.endif

  rjmp  ir_interrupt_done

ir_interrupt_not_me:
.ifdef DEBUG_PRINT_ID_MISMATCH
  ldi   r16, 'X'
  rcall uart_tx
.endif
ir_interrupt_done:
  sei
  reti

.define PORT_TX PORTB
.define DDR_TX DDRB
.define PIN_TX PB1
.define UART_WAIT 1 
#include "uart.asm"

; Execution starts here
reset:
  ; Set outputs for controlling motors
  sbi   DDR_MOTOR, PIN_REV_L
  sbi   DDR_MOTOR, PIN_FWD_L
  sbi   DDR_MOTOR, PIN_FWD_R

  ; Enable TIMER0 with 64 divider (15625/s at 1MHz)
  ldi   r16, 0x3
  out   TCCR0B, r16

  ; Enable PCINT0 (on PB0)
  ldi   r16, 1 << PCINT0
  out   PCMSK, r16

  ; Enable pin change interrupts
  ldi   r16, 1 << PCIE0
  out   PCICR, r16

  rcall uart_init

  sei

loop:
  rjmp	loop

