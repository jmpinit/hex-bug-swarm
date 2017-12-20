;.define UART_WAIT 41 ; 115200 at 16 MHz

uart_init:
  ; Make TX pin output & set it high
  sbi   DDR_TX, PIN_TX
  sbi   PORT_TX, PIN_TX
  ret

uart_delay:
  dec   r16
  brne  uart_delay
  ret

uart_tx:
  ; Uart delay will use r16
  mov   r17, r16

  ; Count 9 bits sent
  ldi   r18, 9

  ; Send start bit
  rjmp  uart_tx_send_0
uart_tx_next_bit:
  ; Move the next bit into the carry
  lsr   r17
  brcc  uart_tx_send_0
uart_tx_send_1:
  sbi   PORT_TX, PIN_TX
  rjmp  uart_tx_finish_bit
uart_tx_send_0:
  cbi   PORT_TX, PIN_TX

  ; Take as much time as the RJMP in the other branch
  nop
  nop
uart_tx_finish_bit:
  ; The time taken here sets the baud rate
  ldi   r16, UART_WAIT
  rcall uart_delay

  ; Loop over the rest of the bits
  dec   r18
  brne  uart_tx_next_bit

  ; Return line to default state
  sbi   PORT_TX, PIN_TX

  ; Stop bit
  ldi   r16, UART_WAIT
  rcall uart_delay

  ret
