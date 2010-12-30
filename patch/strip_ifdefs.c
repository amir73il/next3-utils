#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define MAINKEY_NEXT3 "CONFIG_NEXT3_FS_SNAPSHOT"
#define MAINKEY_EXT4 "CONFIG_EXT4_FS_SNAPSHOT"
#define MAINKEY_E2FS "EXT2FS_SNAPSHOT"
#define MAX_KEY 20

#define LINE_SIZE 1024
#define LINE_LIMIT 80

static void usage(void)
{
	fprintf(stderr, "usage: strip_ifdefs <infile> <outfile> [key [y|n]]\n");
	exit(1);
}

static void print_error(const char *str, const char *filename, int lineno, const char *line)
{
	fprintf(stderr, "%s:%d: %s:\n%s\n",
			filename, lineno, str, line);
}

static void exit_error(const char *str, const char *filename, int lineno, const char *line)
{
	print_error(str, filename, lineno, line);
	exit(1);
}

enum filter {
	FILTER_NONE = 0,	/* no filtering */
	FILTER_DEFINED = 1,	/* keep if defined */
	FILTER_UNDEFINED = -1,	/* keep if undefined */
};

int main(int argc, char *argv[])
{
	char line[LINE_SIZE+2];
	char KEY[MAX_KEY+1];
	FILE *infile, *outfile;
	const char *filename, *filetype;
	const char *MAINKEY = MAINKEY_NEXT3;
	int MAINKEY_LEN = strlen(MAINKEY);
	const char *patchname = "next3_snapshot";
	const char *module = "next3";
	char *key = NULL;
	int len, keylen, keytokens;
	int ifdefno = 0, lineno = 0, nested = 0, hold = 0;
	int snapshot = 0, config = 0, debug = 0, makefile = 0;
	enum filter filter = 0, strip = FILTER_DEFINED;

	if (argc < 3)
		usage();

	infile = fopen(argv[1], "r");
	if (!infile)
		exit_error("failed to open infile",
				argv[1], 0, "");
	filename = rindex(argv[1], '/');
       	if (filename)
		filename++;
	else
		filename = argv[1];
	filetype = rindex(filename, '.');
       	if (filetype)
		filetype++;
	else
		filetype = "";

	if (!strcmp(argv[2], "-"))
		outfile = stdout;
	else
		outfile = fopen(argv[2], "w");
	if (!outfile)
		exit_error("failed to open outfile",
				argv[2], 0, "");
	if (argc > 3) {
		key = argv[3];
		/* convert key to uppercase */
		keylen = 0;
		keytokens = 0;
		while (key[keylen]) {
			KEY[keylen] = toupper(key[keylen]);
			if (key[keylen] == '_')
				keytokens++;
			keylen++;
		}
		KEY[keylen] = 0;
		key = KEY;
		/* default to =n */
		strip = FILTER_UNDEFINED;
	}
	if (argc > 4) {
		switch (argv[4][0]) {
			case 'y':
				strip = FILTER_DEFINED;
				break;
			case 'n':
				strip = FILTER_UNDEFINED;
				break;
			default:
				usage();
		}
	}

	if (strstr(argv[1], "ext4")) {
		module = "ext4";
		patchname = NULL;
		MAINKEY = MAINKEY_EXT4;
		MAINKEY_LEN = strlen(MAINKEY);
	}
	else if (strstr(argv[1], "e2fsprogs")) {
		module = "e2fsprogs";
		patchname = NULL;
		MAINKEY = MAINKEY_E2FS;
		MAINKEY_LEN = strlen(MAINKEY);
	}

	if (!strcmp(filename+1, "config"))
		/* strip config NEXT3_FS_SNAPSHOT_xxx */
		config = 1;

	if (!strcmp(key, "SNAPSHOT") || !strcmp(key, "MAIN"))
		/* strip all snapshot ifdefs */
		key = NULL;

	if (!strncmp(filename, "snapshot", 8)) {
		if (!key && strip < 0)
			exit(0);
	}

	if (!strcmp(filename, "Makefile"))
		makefile = 1;

	if (key && !strcmp(key, "DEBUG")) {
		debug = 1;
		/* remove snapshot_debug files */
		if (!strncmp(filename, "snapshot_debug", 14))
			exit(0);
	}

	fprintf(stderr, "stripping SNAPSHOT%s%s%s from file %s...\n",
			key ? "_" : "", key ? : "", 
			!strip ? "" : (strip > 0 ? "=y" : "=n"),
			filename);

	while (fgets(line, sizeof(line), infile)) {
		lineno++;
		len = strlen(line);
		if (len > LINE_SIZE && line[len-1] != '\n')
			exit_error("line buffer overflow",
					filename, lineno, line);
		
		/* strip off code review comments */
		if (!strncmp(line, "//", 2))
			continue;
		/* strip off warnings and pragmas */
		if (!strncmp(line, "#warning", 8) ||
			!strncmp(line, "#pragma", 7) ||
			!strncmp(line, "__attribute__", 13))
			continue;

		if (snapshot && len > LINE_LIMIT+1)
			print_error("line too long inside snapshot patch",
					filename, lineno, line);

		if (config) {
			if (!hold && *line == '\n') {
				hold = 1;
				continue;
			} else if (!strncmp(line, "config ", 7)) {
				if (debug) {
					if (!strncmp(line+7, MAINKEY+7, MAINKEY_LEN-15) &&
						!strncmp(line+MAINKEY_LEN-8, "DEBUG", 5)) {
						/* strip debug config */
						hold = 0;
						filter = FILTER_UNDEFINED;
					} else {
						/* stop filtering debug config */
						filter = FILTER_NONE;
					}
				} else if (!strncmp(line+7, MAINKEY+7, MAINKEY_LEN-7)) {
					if (!key)
						/* discard all snapshot sub configs */
						break;
					snapshot = 1;
					if (!strncmp(line+MAINKEY_LEN+1, key, keylen)) {
						/* start filtering snapshot sub config */
						if (filter)
							exit_error("nested snapshot sub config",
									filename, lineno, line);
						filter = FILTER_UNDEFINED;
					} else {
						/* stop filtering snapshot sub config */
						filter = FILTER_NONE;
					}
				}
			} else if (snapshot || debug) {
				if (filter) {
					if (!strncmp(line+1, "bool ", 5)) {
						if (patchname)
							printf("%.*s%s_%s.patch%.*s\n\n",
									keytokens+2, "====",
									patchname,
									argv[3],
									keytokens+2, "====");
						if (module)
							printf("%s: ", module);
						printf("%.*s\n\n", len-9, line+7);
					} else if (!strncmp(line+1, "  ", 2))
						printf("%s", line+3);
				} else if (key) {
				       	if (!strncmp(line+1, "depends on ", 11) && 
						!strncmp(line+12+MAINKEY_LEN+1, key, keylen))
						exit_error("snapshot sub config dependecy",
								filename, lineno, line);
				} 
			}
			if (hold && filter != FILTER_UNDEFINED) {
				hold = 0;
				fputs("\n", outfile);
			}
		} else if (debug) {
			/* strip lines with "snapshot_debug" */
			if (strstr(line, "snapshot_debug"))
				continue;
		} else if (makefile) {
			/* strip snapshot files from makefile */
			if (!key && strip < 0 && strstr(line, "snapshot.o"))
				continue;
		} else if (!strncmp(line, " *", 2) || !strncmp(line, "*/", 2)) {
			if (!key && strip < 0) {
				if (!hold && !strncmp(line, " *\n", 3)) {
					/* hold 1 empty line */
					hold = 1;
					continue;
				} else if (strstr(line+2, "Amir") || strstr(line+2, "CTERA")) {
					/* strip off copyright */
					hold = 0;
					continue;
				} else if (hold) {
					/* output held empty line */
					hold = 0;
					fputs(" *\n", outfile);
				}
			}
		} else if (!strncmp(line, "//", 2)) {
			/* strip off code review comments */
			if (!key)
				continue;
		} else if (line[0] == '#') {
			char *ifdef = NULL;
			/* strip off warnings and pragmas */
			if (!key && (!strncmp(line+1, "warning", 7) ||
					!strncmp(line+1, "pragma", 6)))
				continue;

			/* strip off snapshot file includes */
			if (!key && strip < 0 &&
					!strncmp(line+1, "include", 7) &&
					!strncmp(line+10, "snapshot.h", 10))
				continue;

			/* filter define MAINKEY */
			if (!strncmp(line+1, "define", 6) &&
				!strncmp(line+8, MAINKEY, MAINKEY_LEN) &&
				(!key || !strncmp(line+8+MAINKEY_LEN+1, key, keylen)))
				continue;

			/* filter ifdef/ifndef MAINKEY */
			if (!strncmp(line+1, "if ", 3))
				ifdef = line+4;
			else if (!strncmp(line+1, "ifdef", 5))
				ifdef = line+7;
			else if (!strncmp(line+1, "ifndef", 6))
				ifdef = line+8;
			if (ifdef) {
				ifdefno++;
				nested++;
				if (!ifdefno) {
					exit_error("unbalanced ifdef in h file",
							filename, lineno, line);
				} else if (nested < 0) {
					exit_error("nested non-snapshot ifdef inside snapshot patch",
							filename, lineno, line);
				} else if (*filetype == 'h' && ifdefno == 1 && line[3] == 'n') {
					/* ignore first ifndef in h files */
					nested--;
				} else if (!strncmp(ifdef, MAINKEY, MAINKEY_LEN)) {
					/* snapshot ifdef */
					if (!snapshot)
						/* set first snapshot nesting level */
						snapshot = nested;
					if (filter == FILTER_UNDEFINED ||
							(filter && !key && strip == FILTER_UNDEFINED))
						exit_error("snapshot ifdef nested inside snapshot ifndef",
								filename, lineno, line);
					if (!key || !strncmp(ifdef+MAINKEY_LEN+1, key, keylen))
						/* filter snapshot ifdefs that match key */
						filter = (line[3] == 'n' ? -strip : strip);
					if (filter)
						/* strip the ifdef */
						continue;
				} else {
					/* non-snapshot ifdef line */
					if (snapshot)
						/* no more nesting allowed inside snapshot patch */
						nested = -nested;
				}
			} else if (!strncmp(line+1, "else", 4)) {
				if (!nested)
					exit_error("else without ifdef",
							filename, lineno, line);
				if (nested > 0) {
					filter = -filter;
					if (filter)
						/* strip the else line */
						continue;
				}
			} else if (!strncmp(line+1, "endif", 5)) {
				if (!nested) {
					if (*filetype == 'h' || len > 7)
						/* ignore unbalanced last endif in h files */
						ifdefno = -1;
					else
						exit_error("endif without ifdef",
								filename, lineno, line);
				} else if (nested < 0) {
					/* endif nested non-snapshot ifdef inside snapshot patch */
					nested = -nested-1;
				} else {
					/* endif nested ifdef */
					nested--;
					if (nested < snapshot)
						snapshot = 0;
					if (filter) {
						if (!key && snapshot &&
								(strip == FILTER_DEFINED || nested > snapshot))
							filter = FILTER_DEFINED;
						else
							filter = FILTER_NONE;
						/* strip the endif line */
						continue;
					}
				}
			}
		}

		if (filter != FILTER_UNDEFINED)
			fputs(line, outfile);
	}

	if (config)
		puts("");

	fclose(infile);
	fclose(outfile);
}
