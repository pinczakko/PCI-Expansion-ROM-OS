/*
Description:
This program works by appending the binary of the
second file into the first file, and writing the result into the third input
filename. The first and second file remain unchanged.
*/
#include <stdlib.h>
#include <stdio.h>

typedef unsigned char UCHAR;
typedef unsigned int UINT;
typedef unsigned long ULONG;

int MergeFile(FILE* fp1, FILE* fp2, FILE* fpOutput);

int main(int argc, char* argv[])
{
	FILE*	fp1;
	FILE*   fp2;
	FILE*   fp3;

	if(argc != 4) /* not enough parameter */
	{
		printf("Usage: %s  [filename1] [filename2] [output filename]\n",argv[0]);
		return -1;
	}

	/* argv[1] is pointer to the filename parameter from user */
	if( (fp1 = fopen( argv[1] , "rb+")) == NULL)
	{
		printf("Error opening file1\nclosing program ...");
		return -1;
	}

	if( (fp2 = fopen( argv[2] , "rb+")) == NULL)
	{
		printf("Error opening file2\nclosing program ...");
		fclose(fp1);
		return -1;
	}

	if( (fp3 = fopen( argv[3] , "wb+")) == NULL)
	{
		printf("Error opening file3\nclosing program ...");
		fclose(fp1);
		fclose(fp2);
		return -1;
	}

	if(MergeFile(fp1, fp2, fp3) == -1)
	{
		printf("Error merging file1 and file2\nclosing program ...");
		return -1;
	}
	
	fclose(fp1);
	fclose(fp2);
	fclose(fp3);
	
	return 0;
}

int MergeFile(FILE* fp1, FILE* fp2, FILE* fpOutput)
{
 long lFile1Size, lFile2Size;
 char* pchBuff;

 if(fseek(fp1, 0, SEEK_END) != 0)
 	return -1;//error

 if( (lFile1Size = ftell(fp1)) == -1)
 	return -1;//error

 if(fseek(fp2, 0, SEEK_END) != 0)
 	return -1;//error

 if( (lFile2Size = ftell(fp2)) == -1)
 	return -1;//error

 if( (pchBuff = malloc(sizeof(char)*lFile1Size)) == 0)
 	return -1;

 if(fseek(fp1, 0, SEEK_SET) != 0 )
 	{
	free(pchBuff);
	return -1;
	}

	fread(pchBuff, sizeof(char), lFile1Size, fp1);
	fwrite(pchBuff,sizeof(char), lFile1Size, fpOutput);
	free(pchBuff);

if(fseek(fpOutput, 0, SEEK_END) != 0 )
 	return -1;

if( (pchBuff = malloc(sizeof(char)*lFile2Size)) == 0)
 	return -1;

if(fseek(fp2, 0, SEEK_SET) != 0 )
 {
   free(pchBuff);
   return -1;
 }

 	fread(pchBuff, sizeof(char), lFile2Size, fp2);
	fwrite(pchBuff,sizeof(char), lFile2Size, fpOutput);
	free(pchBuff);

 return 0;//success

}
