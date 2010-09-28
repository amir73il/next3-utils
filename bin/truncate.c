#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE
#define _FILE_OFFSET_BITS 64

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>

#define EXABYTES(x)     ((long long)(x) << 60)
#define PETABYTES(x)    ((long long)(x) << 50)
#define TERABYTES(x)    ((long long)(x) << 40)
#define GIGABYTES(x)    ((long long)(x) << 30)
#define MEGABYTES(x)    ((long long)(x) << 20)
#define KILOBYTES(x)    ((long long)(x) << 10)

long long
cvtnum(char *s)
{
	long long	i;
	char		*sp;
	int		c;

	i = strtoll(s, &sp, 0);
	if (i == 0 && sp == s)
		return -1LL;
	if (*sp == '\0')
		return i;
	if (sp[1] != '\0')
		return -1LL;

	c = tolower(*sp);
	switch (c) {
	case 'k':
		return KILOBYTES(i);
	case 'm':
		return MEGABYTES(i);
	case 'g':
		return GIGABYTES(i);
	case 't':
		return TERABYTES(i);
	case 'p':
		return PETABYTES(i);
	case 'e':
		return  EXABYTES(i);
	}

	return -1LL;
}


int main(int argc, char *argv[])
{
	off_t size;

	if (argc < 3 || strcmp(argv[1], "-s") != 0) {
		fprintf(stderr, "usage: truncate -s length filename\n");
		return -EINVAL;
	}

	size = cvtnum(argv[2]);
	if (size < 0) {
		fprintf(stderr, "invalid length '%s'\n", argv[2]);
		return -EINVAL;
	}	

	return truncate(argv[3], size);
}
