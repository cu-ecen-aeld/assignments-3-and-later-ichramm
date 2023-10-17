
# CROSS_COMPILE is the prefix of the compiler
# e.g. aarch64-none-linux-gnu- for aarch64 (note the trailing dash)
CC=$(CROSS_COMPILE)gcc

writer: writer.c
	$(CC) -o writer writer.c

clean:
	rm -f writer *.o
