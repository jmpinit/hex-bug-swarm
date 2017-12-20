#include <avr/io.h>
#include <util/delay.h>

#define CMD_STOP            0b000001
#define CMD_FORWARD         0b000111
#define CMD_BACKWARD        0b011001
#define CMD_LEFT_FORWARD    0b000011
#define CMD_LEFT_BACKWARD   0b010001
#define CMD_RIGHT_FORWARD   0b000101
#define CMD_RIGHT_BACKWARD  0b001001

inline void ir_on() {
  TCCR1A = 1 << COM1A0; // toggle OCR1A on compare match
  TCCR1B |= 1 << CS10;
}

inline void ir_off() {
  TCCR1A &= ~(1 << COM1A0);
  TCCR1B &= ~(1 << CS10);
  PORTB &= ~(1 << PB1);
}

// 8 bits of data
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

void uart_init() {
  // Set TX to be output
  DDRD |= 1 << PD1;

  UBRR0 = 3; // Set 250k baud

  // Enable TX and RX
  UCSR0B |= (1 << TXEN0) | (1 << RXEN0);

  // 8 bit
  UCSR0C = (1 << UCSZ00) | (1 << UCSZ01);
}

char uart_read() {
  while (!(UCSR0A & (1 << RXC0))) {}
	return UDR0;
}

void uart_write(char c) {
  while (!(UCSR0A & (1 << UDRE0)));
	UDR0 = c;
}

int main() {
  TCCR1A = (1 << COM1A0); // toggle OCR1A on compare match
  TCCR1B = (1 << WGM12) | (1 << CS10);
  OCR1A = 209;//F_CPU/8/2/30 - 1;//(F_CPU/2/38000 - 1) * 2;

  DDRB |= 1 << PB1;

  uart_init();

  for (;;) {
    uint8_t c = uart_read();
    send_command(c);
    uart_write(c);
  }

  return 0;
}
