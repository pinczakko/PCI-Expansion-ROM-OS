#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DIAGNOSTIC

typedef unsigned char UCHAR;
typedef unsigned long ULONG;
typedef unsigned int  UINT;

int main(int argc, char* argv[])
{
  FILE* fp1;
  long lFileSize, lTargetFileSize, lPaddingSize;
  char* pchTemp[15];
  char* pchBuff;

  if(argc != 3)
  {
	printf("Usage: %s [filename] [target byte size]\n", argv[0]);
	return -1; //error
  }

  if( (fp1 = fopen(argv[1], "ab")) == NULL)
  {
	printf("error opening file\n closing program...\n");
	return -1;
  }

  lTargetFileSize = strtoul(argv[2], pchTemp, 10);

#ifdef DIAGNOSTIC
  printf("lTargetFileSize = %ld\n", lTargetFileSize);
#endif //DIAGNOSTIC

  if(fseek(fp1, 0, SEEK_END) != 0)
  {
	printf("error seeking file\n closing program...\n");
	return -1;
  }

  if( (lFileSize = ftell(fp1)) == -1)
  {
	printf("error counting file size\n closing program...\n");
	return -1;
  }

  if( lFileSize >= lTargetFileSize)
  {
	printf("Input error, Target file size is smaller than the original file size\n");
        return -1;
  }
 
  /*
    Zero extend the target file
  */
  lPaddingSize = lTargetFileSize - lFileSize;

#ifdef DIAGNOSTIC
  printf("lPaddingSize = %ld\n", lPaddingSize);
  printf("lFileSize= %ld\n", lFileSize);
#endif //DIAGNOSTIC  

  pchBuff = (char*) malloc(sizeof(char) * lPaddingSize );
  memset(pchBuff, 0, sizeof(char) * lPaddingSize );
  fseek(fp1, 0, SEEK_END);
  fwrite( pchBuff, sizeof(char), lPaddingSize, fp1);
  fclose(fp1);

  if(pchBuff != NULL)
	free(pchBuff);  

  return 0;//success
}

