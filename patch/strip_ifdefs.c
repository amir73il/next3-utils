#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define MAINKEY "CONFIG_NEXT3_FS_SNAPSHOT"
#define MAINKEY_LEN 24

#define LINE_SIZE 120
#define LINE_LIMIT 80

static void usage(void)
{
	fprintf(stderr, "usage: strip_ifdefs <infile> <outfile> [key [=y|n]]\n");
	exit(1);
}

static void exit_error(const char *str, const char *filename, int lineno, const char *line)
{
	fprintf(stderr, "%s:%d: %s\n:%s\n",
			filename, lineno, str, line);
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
	FILE *infile, *outfile;
	const char *filename, *filetype;
	char *key = NULL;
	int len, keylen, ifdefno = 0, lineno = 0;
	int nested = 0, snapshot = 0, config = 0;
	enum filter filter = 0, strip = 0;

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

	outfile = fopen(argv[2], "w");
	if (!outfile)
		exit_error("failed to open outfile",
				argv[2], 0, "");
	if (argc > 3) {
		key = argv[3];
		/* convert key to uppercase */
		keylen = 0;
		while (key[keylen]) {
			key[keylen] = toupper(key[keylen]);
			keylen++;
		}
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

	if (!strcmp(filename, "Kconfig"))
		/* strip config NEXT3_FS_SNAPSHOT_xxx */
		config = 1;

	fprintf(stderr, "stripping %s_%s%s from file %s...\n",
			MAINKEY, key ? : "", 
			!strip ? "" : (strip > 0 ? "=y" : "=n"),
			filename);

	if (!key && !strncmp(filename, "snapshot", 8))
		/* snapshot* files are ifdefed in Makefile */
		nested = snapshot = 1;

	while (fgets(line, sizeof(line), infile)) {
		lineno++;
		len = strlen(line);
		if (len > LINE_SIZE && line[len-1] != '\n')
			exit_error("line buffer overflow",
					filename, lineno, line);
		if (snapshot && len > LINE_LIMIT+1)
			exit_error("line too long inside snapshot patch",
					filename, lineno, line);

		if (config) {
			if (!strncmp(line, "config ", 7)) {
				if (!strncmp(line+7, MAINKEY+7, MAINKEY_LEN-7)) {
					if (!snapshot) {
						/* snapshot main config */
						nested = snapshot = 1;
					} else {
						/* snapshot sub config */
						nested = 2;
						if (!key)
							/* discard all snapshot sub configs */
							break;
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
				}
			} else if (snapshot) {
				if (filter) {
					if (!strncmp(line+1, "bool ", 5))
						printf("%.*s\n\n", len-9, line+7);
					else if (!strncmp(line+1, "  ", 2))
						printf("%s", line+3);
				} else if (key) {
				       	if (!strncmp(line+1, "depends on ", 11) && 
						!strncmp(line+12+MAINKEY_LEN+1, key, keylen))
						exit_error("snapshot sub config dependecy",
								filename, lineno, line);
				} 
			}
		} else if (line[0] == '#') {
			char *ifdef = NULL;
			/* strip off warnings and pragmas */
			if (!key && (!strncmp(line+1, "warning", 7) ||
					!strncmp(line+1, "pragma", 6)))
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
					if (filter == FILTER_UNDEFINED)
						exit_error("snapshot ifdef nested inside snapshot ifndef",
								filename, lineno, line);
					if (key && !strncmp(ifdef+MAINKEY_LEN+1, key, keylen))
						/* filter snapshot ifdefs that match key */
						filter = (line[3] == 'n' ? -strip : strip);
					if (!key) {
						/* no key - filter/trim all snapshot subkeys */
						if (nested > snapshot) {
							filter = (line[3] == 'n' ? 
									FILTER_UNDEFINED : FILTER_DEFINED);
						} else {
							ifdef[MAINKEY_LEN] = '\n';
							ifdef[MAINKEY_LEN+1] = '\0';
						}
					}
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
				if (nested > 0)
					filter = -filter;
				if (filter)
					/* strip the else line */
					continue;
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
						if (!key && snapshot && nested > snapshot)
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

	fclose(infile);
	fclose(outfile);
}
