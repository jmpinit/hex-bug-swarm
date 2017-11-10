#include <avr/io.h>
#include <util/delay.h>

inline void ir_on() {
  TCCR1B |= 1 << CS10;
}

inline void ir_off() {
  TCCR1B &= ~(1 << CS10);
}

void forward_left() {
  // long pulse

  ir_on();
  _delay_ms(2);

  ir_off();
  _delay_us(400);

  // med pulses

  for (int i = 0; i < 2; i++) {
    ir_on();
    _delay_us(1200);

    ir_off();
    _delay_us(400);
  }

  // short pulses

  for (int i = 0; i < 4; i++) {
    ir_on();
    _delay_us(400);

    ir_off();
    _delay_us(400);
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
    //forward_left();
    _delay_ms(1000);
  }

  return 0;
}
