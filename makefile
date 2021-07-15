CC=gcc
CFLAGS=-Wall -Wextra
LDLIBS=-static

EXEC=pgma
OBJS=pgma.o \
meuAlocador.o

all: $(EXEC)

$(EXEC): $(OBJS)

clean:
	rm -f *.o

purge: clean
	rm -f $(EXEC)