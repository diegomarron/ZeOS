/*
 * io.c - 
 */

#include <io.h>

/**************/
/** Screen  ***/
/**************/

Byte x, y=15;
Byte ox,oy;


inline void save_and_set_xy(Byte _x, Byte _y){
  ox=x; x=_x;
  oy=y; y=_y;
}

inline void restore_xy(){
  x=ox;
  y=oy;
}


/* Read a byte from 'port' */
Byte inb (unsigned short port)
{
  Byte v;

  __asm__ __volatile__ ("inb %w1,%0":"=a" (v):"Nd" (port));
  return v;
}

void outb(Byte __val, unsigned short __port){
  __asm__ __volatile__("outb %0,%1" : : "a" (__val), "dN" (__port));
}



void printc(char c)
{
  Word ch = (Word) (c & 0x00FF) | 0x0200;
  DWord screen;

  switch(c){

  case '\n':
    x=0;
    if ( ++y >= NUM_ROWS) y=0;
    break;
  default:
      screen = 0xb8000 + (y * NUM_COLUMNS + x) * 2;
      __asm__ __volatile__ ( "movb %0, %%al; outb $0xe9" ::"a"(c));
      if (++x >= NUM_COLUMNS)
      {
        x = 0;
        if (++y >= NUM_ROWS)
          y = 0;
      }
      asm("movw %0, (%1)" : : "r"(ch), "r"(screen));

  }
}


void printk(char *string)
{
  int i;
  for (i = 0; string[i]; i++)
    printc(string[i]);
}

void printd(int num){
  char str[12];
  __itoa(num,&str[0],10,0);
  printk(&str[0]);

}


// A new wrapper around printc function,
// we can change the offset on video memory where to write
// positioning anywhere
void printk_xy(int _x, int _y, char *string){
  int i;

  save_and_set_xy( (Byte) _x, (Byte) _y);

  for (i = 0; string[i]; i++)
    printc(string[i]);
  restore_xy();

}
