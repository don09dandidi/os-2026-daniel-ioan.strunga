CFLAGS = -Wall -pthread
PROGS = race mutex sem order parking atomic
all: $(PROGS)
%: %.c
	gcc $(CFLAGS) -o $@ $<
clean:
	rm -f $(PROGS) sem2 order1 parking1
