#include "tn10def.inc"

; PB0 -> PB1

.cseg
.org 0
  rjmp  reset

; Execution starts here
reset:
  ; Make PB1 an output
  sbi   DDRB, PB1
loop:
  in    r16, PINB
  andi  r16, 1 ; Mask only PB0
  lsl   r16 ; Move value to PB1
  out   PORTB, r16 ; Output
  rjmp	loop

