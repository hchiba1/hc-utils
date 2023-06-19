#!/usr/bin/env runc
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_LEN 10000

int main() {
    char line[BUF_LEN];
    int max_len = 0;
    int max_no = 0;

    int no = 0;
    while (fgets(line, BUF_LEN, stdin) != NULL) {
        no++;
        int len = strlen(line);
        
        if (line[len - 1] == '\n') {
            line[len - 1] = '\0';
        } else {
            fprintf(stderr, "In line:%d line_len exceeds BUF_LEN=%d\n", no, BUF_LEN);
            exit(1);
        }

        if (len > max_len) {
            max_len = len;
            max_no = no;
        }
    }

    printf("len = %d in line %d among %d lines\n", max_len, max_no, no);

    return 0;
}
