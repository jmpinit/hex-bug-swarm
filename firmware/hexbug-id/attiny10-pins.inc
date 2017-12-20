.define PORT_RX     PORTB
.define PINPORT_RX  PINB
.define PIN_RX      PB0

.define DDR_MOTOR   DDRB
.define PORT_MOTOR  PORTB

; The ATTiny10 rides the Hex Bug's left motor driver like a backpack
; and the lower four pins are soldered directly down.
; PB3 gets a fly wire to the lower right (FWD) pin of the right motor controller.

;      +-------+
;     =|PB0 PB3|=-----> to fwd on 2nd motor controller
; +---=|GND VCC|=---+
; | +-=|PB1 PB2|=-+ |
; | |  +-------+  | |
; | |             | |
; | |  +-------+  | |
; | | =|M1   M2|= | |
; +---=|GND VCC|=---+
;   +-=|BAK FWD|=-+
;      +-------+

.define PIN_REV_L   PB1
.define PIN_FWD_L   PB2
.define PIN_FWD_R   PB3
