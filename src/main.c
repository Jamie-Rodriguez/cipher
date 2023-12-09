#include "cipher.h"
#include <ctype.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define OUTPUT_TEXT_SIZE 0x400

typedef struct EncryptionConfig {
        char* key;
        size_t key_len;
        char* text;
        size_t len;
} EncryptionConfig;


void validate_num_command_line_args(bool decipher_mode, int num_command_line_args) {
        if ((!decipher_mode && num_command_line_args != 4) ||
            (decipher_mode && num_command_line_args != 5)) {
                fprintf(stderr, "Error: Invalid number of arguments\n");
                exit(EXIT_FAILURE);
        }
}


void write_help_string(size_t length, char output[length]) {
        const char help_text[] =
            "Usage: cipher [-d|--decipher] [cipher] key plaintext\n"
            "Options:\n"
            "    -h, --help                     Display this help message\n"
            "    -d, --decipher                 Decipher the ciphertext\n"
            "    -c, --caesar   <key> <text>    Caesar cipher\n"
            "                                   Provide the key as a *single* letter to rotate by\n"
            "    -v, --vigenere <key> <text>    Vigenère cipher\n\n"
            "NOTE: Any non-alphabetic characters in the plaintext, ciphertext or key are ignored\n"
            "      This is for readability, but when using you should strip all non-alphabetic characters (including spaces), and use only one case.\n\n"
            "Example Usages:\n"
            "    cipher --caesar J \"HELLOWORLD\"\n"
            "    cipher --decipher -c J \"QNUUX FXAUM\"\n"
            "    cipher --vigenere ARAGON \"Gondor calls for aid!\"\n"
            "    cipher --decipher -v \"Legolas said\" \"Elkm\'ce lskqqr xns sottibv es Ogpnysrl\"\n";

        snprintf(output, length, "%s", help_text);
}

void run_caesar_cipher(const EncryptionConfig* config, bool decipher, char* output) {
        // Destructure the EncryptionConfig for convenience
        const char* key = config->key;
        const size_t key_len = config->key_len;
        const char* rawtext = config->text;
        const size_t length = config->len;

        if (key_len != 1) {
                fprintf(stderr, "Error: Key should be a single letter to rotate by\n");
                exit(EXIT_FAILURE);
        }

        strncpy(output, rawtext, length);

        // 'output' is mutated here
        if (decipher)
                decipher_caesar((char) toupper(key[0]), length, output);
        else
                caesar((char) toupper(key[0]), length, output);
}

void run_vigenere_cipher(const EncryptionConfig* config, bool decipher, char* output) {
        // Destructure the EncryptionConfig for convenience
        const char* key = config->key;
        const size_t key_len = config->key_len;
        const char* rawtext = config->text;
        const size_t length = config->len;

        strncpy(output, rawtext, length);

        // 'output' is mutated here
        if (decipher)
                decipher_vigenere(key_len, key, length, output);
        else
                vigenere(key_len, key, length, output);
}


int main(const int argc, char const* argv[]) {
        if (argc <= 1) {
                fprintf(stderr, "Error: No command line arguments provided\n");
                exit(EXIT_FAILURE);
        }

        struct option long_options[] = {
                {    "help",       no_argument, NULL, 'h'},
                {"decipher",       no_argument, NULL, 'd'},
                {  "caesar", required_argument, NULL, 'c'},
                {"vigenere", required_argument, NULL, 'v'},
                {      NULL,                 0, NULL,   0}  // Null terminator for the options array
        };

        char output_text[OUTPUT_TEXT_SIZE] = { 0 };

        int option = 0;
        int option_index = 0;
        bool decipher = false;

        while ((option = getopt_long(argc, argv, "hdc:v:", long_options, &option_index)) != -1) {
                switch (option) {
                        case 'h': {
                                write_help_string(OUTPUT_TEXT_SIZE, output_text);
                                break;
                        }
                        case 'd':
                                decipher = true;
                                break;
                        case 'c': {
                                validate_num_command_line_args(decipher, argc);

                                const char* key = argv[argc - 2];
                                const char* rawtext = argv[argc - 1];

                                EncryptionConfig config = {
                                        .key = key,
                                        .key_len = strlen(key),
                                        .text = rawtext,
                                        .len = strlen(rawtext),
                                };

                                run_caesar_cipher(&config, decipher, output_text);

                                break;
                        }
                        case 'v': {
                                validate_num_command_line_args(decipher, argc);

                                const char* key = argv[argc - 2];
                                const char* rawtext = argv[argc - 1];

                                EncryptionConfig config = {
                                        .key = key,
                                        .key_len = strlen(key),
                                        .text = rawtext,
                                        .len = strlen(rawtext),
                                };

                                run_vigenere_cipher(&config, decipher, output_text);

                                break;
                        }
                        default:
                                exit(EXIT_FAILURE);
                }
        }

        printf("%s\n", output_text);

        return EXIT_SUCCESS;
}
