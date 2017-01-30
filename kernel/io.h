#ifndef __IO_H__
#define __IO_H__

unsigned char in(unsigned short _port);
void out(unsigned short _port, unsigned char _data);

void clrscr();
void print(const char *_message);

#endif //__IO_H__
