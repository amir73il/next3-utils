/*
 * fallocate - utility to use the fallocate system call
 *
 * Copyright (C) 2008 Red Hat, Inc. All rights reserved.
 * Written by Eric Sandeen <sandeen@redhat.com>
 *
 * cvtnum routine taken from xfsprogs,
 * Copyright (c) 2003-2005 Silicon Graphics, Inc.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it would be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

//#define _LARGEFILE_SOURCE
//#define _LARGEFILE64_SOURCE
//#define _FILE_OFFSET_BITS 64
//#define _XOPEN_SOURCE 600

#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>

// #include <linux/falloc.h>
#define FALLOC_FL_KEEP_SIZE	0x01

void usage(void)
{
	printf("Usage: fallocate [-ntmrs] [-o offset] -l length filename\n"
			" -n\tkeep file size.\n"
			" -t\tmodify file size with truncate.\n"
			" -m\tmmap file and write to all pages.\n"
			" -r\twrite radom data to pages.\n"
			" -s\tsync file before returning.\n");
	exit(EXIT_FAILURE);
}

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

int main(int argc, char **argv)
{
	int	fd;
	char	*fname;
	int	opt;
	off_t	length = -2LL;
	off_t	offset = 0;
	int	falloc_mode = 0;
	int	error = 0;
	int	tflag = 0, mflag = 0, rflag = 0, sflag = 0;

	while ((opt = getopt(argc, argv, "nl:o:tmrs")) != -1) {
		switch(opt) {
		case 'n':
			/* do not change filesize */
			falloc_mode = FALLOC_FL_KEEP_SIZE;
			break;
		case 'l':
			length = cvtnum(optarg);
			break;
		case 'o':
			offset = cvtnum(optarg);
			break;
		case 't':
			tflag++;
			break;
		case 'm':
			mflag++;
			break;
		case 'r':
			rflag++;
			break;
		case 's':
			sflag++;
			break;
		default:
			usage();
		}
	}

	if (length == -2LL) {
		printf("Error: no length argument specified\n");
		usage();
	}

	if (length <= 0) {
		printf("Error: invalid length value specified\n");
		usage();
	}

	if (offset < 0) {
		printf("Error: invalid offset value specified\n");
		usage();
	}

	if (tflag && (falloc_mode & FALLOC_FL_KEEP_SIZE)) {
		printf("-n and -t options incompatible\n");
		usage();
	}

	if (tflag && offset) {
		printf("-t and -o options incompatible\n");
		usage();
	}

	if (optind == argc) {
		printf("Error: no filename specified\n");
		usage();
	}

	fname = argv[optind++];

	/* Should we create the file if it doesn't already exist? */
	fd = open(fname, O_CREAT|O_RDWR/*|O_LARGEFILE*/);
	if (fd < 0) {
		perror("Error opening file");
		exit(EXIT_FAILURE);
	}

	if (tflag || mflag)
		error = ftruncate(fd, length);
	else
		error = syscall(SYS_fallocate, fd, falloc_mode, offset, length);
		//error = posix_fallocate(fd, offset, length);

	if (rflag) {
		time_t now = time(NULL);
		srand(now);
	}

	while (!error && mflag && length > 0) {
		char *start, *end, *p;
		const int pagesize = 4096;
		int len = length;//16*1024*pagesize;
		
		if (len > length)
			len = length;

		start = mmap(NULL, len, PROT_WRITE, MAP_SHARED, fd, offset);
		if (start == MAP_FAILED) {
			error = (int)start;
			break;
		}

		end = start + len;
		for (p = start; p < end; p += pagesize)
			*(int *)p = rflag ? rand() : 0;

		if (!error)
			error = munmap(start, len);
		
		length -= len;
		offset += len;
	}

	if (error < 0) {
		perror("fallocate failed");
		exit(EXIT_FAILURE);
	}

	if (sflag)
		fdatasync(fd);
	close(fd);
	return 0;
}
