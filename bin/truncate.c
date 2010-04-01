#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

int main(int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "usage: truncate <path> <length>\n");
		return -EINVAL;
	}

	return truncate(argv[1], atoi(argv[2]));
}
