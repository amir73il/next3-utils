PROGS:= truncate fallocate

all: ${PROGS}

install:
	install -m 755 next4 ${PROGS} ${DESTDIR}
	
clean:
	rm -rf ${PROGS} *snap *.next4
