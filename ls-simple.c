#include <stdio.h>
#include <dirent.h>

int main(int argc, char *argv[]) {
    const char *input_path = (argc > 1) ? argv[1] : ".";

    DIR *dir = opendir(input_path);
    if (!dir) {
        perror("opendir");
        return 1;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        // "." または ".." をスキップ
        if (entry->d_name[0] == '.' && entry->d_name[1] == '\0' ||
            entry->d_name[0] == '.' && entry->d_name[1] == '.' && entry->d_name[2] == '\0') {
            continue;
        }
        printf("%s\n", entry->d_name);
    }

    closedir(dir);
    return 0;
}
