#include "io.h"

const char *os_string;

void main()
{
  clrscr();
  print(os_string);

  for(;;);
}

const char *os_string = "Pinczakko OS version 0.0.1";
