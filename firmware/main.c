#include <avr/io.h>
#include <util/delay.h>

#define CMD_LEFT_FORWARD    0b00011
#define CMD_LEFT_BACKWARD   0b10001
#define CMD_RIGHT_FORWARD   0b00101
#define CMD_RIGHT_BACKWARD  0b01001

inline void ir_on() {
  TCCR1B |= 1 << CS10;
}

inline void ir_off() {
  TCCR1B &= ~(1 << CS10);
}

// 6 bits of data
void send_command(uint8_t data) {
  // Start pulse (long)

  ir_on();
  _delay_ms(2);

  ir_off();
  _delay_us(400);

  for (int i = 0; i < 8; i++) {
    if (data & (1 << i)) {
      ir_on();
      _delay_us(1200);

      ir_off();
      _delay_us(400);
    } else {
      ir_on();
      _delay_us(400);

      ir_off();
      _delay_us(400);
    }
  }

  ir_on();
  _delay_us(500);

  ir_off();
}

int main() {
  TCCR1A = (1 << COM1A0); // toggle OCR1A on compare match
  TCCR1B = (1 << WGM12) | (1 << CS10);
  OCR1A = 209;//F_CPU/8/2/30 - 1;//(F_CPU/2/38000 - 1) * 2;

  DDRB |= 1 << PB1;

  for (;;) {
    /*PORTB |= 1 << PB1;
    _delay_ms(500);
    PORTB &= ~(1 << PB1);
    _delay_ms(500);*/
    send_command(CMD_LEFT_FORWARD);
    _delay_ms(1000);
    send_command(CMD_LEFT_BACKWARD);
    _delay_ms(1000);
    send_command(CMD_RIGHT_FORWARD);
    _delay_ms(1000);
    send_command(CMD_RIGHT_BACKWARD);
    _delay_ms(1000);
  }

  return 0;
}
