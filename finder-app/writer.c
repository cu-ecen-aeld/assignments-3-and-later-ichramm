#include <stdlib.h>
#include <stdio.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>

int main(int argc, char *argv[])
{
    openlog("writer", LOG_PID|LOG_CONS, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Invalid number of arguments. Usage: %s <file> <string>", argv[0]);
        exit(EXIT_FAILURE);
    }

    char *file = argv[1];
    char *string = argv[2];

    syslog(LOG_DEBUG, "Writing %s to %s", string, file);

    // pre: directory exists
    FILE *fp = fopen(file, "w");
    if (fp == NULL) {
        syslog(LOG_ERR, "Failed to open file %s: %s", file, strerror(errno));
        exit(EXIT_FAILURE);
    }

    fprintf(fp, "%s", string); // does not append newline
    fclose(fp);

    closelog();
    return EXIT_SUCCESS;
}
