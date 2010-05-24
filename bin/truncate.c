#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>

int main(int argc, char *argv[])
{
	off_t size;

	if (argc < 2) {
		fprintf(stderr, "usage: truncate <path> <length[K|M|G]>\n");
		return -EINVAL;
	}

	size = atoi(argv[2]);
	if (size == 0 && strcmp(argv[2], "0") != 0) {
		fprintf(stderr, "invalid length '%s'\n", argv[2]);
		return -EINVAL;
	}	

	switch (argv[2][strlen(argv[2])-1]) {
		case 'G':
			size *= 1024;
		case 'M':
			size *= 1024;
		case 'K':
			size *= 1024;
	}

	return truncate(argv[1], size);
}
