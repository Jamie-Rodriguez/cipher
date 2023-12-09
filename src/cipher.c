#include "cipher.h"
#include <ctype.h>


static inline char rotate(char base, int rotation, char c) {
        return (char) (c - base + rotation) % 26 + base;
}

// WARNING: mutates 'plaintext'!
void caesar(char key, size_t length, char plaintext[length]) {
        if (!isalpha(key)) return;

        const char base_upper = 'A';
        const int rotation_upper = toupper(key) - base_upper;

        const char base_lower = 'a';
        const int rotation_lower = tolower(key) - base_lower;

        for (size_t c = 0; c < length; c++) {
                // Ignore non-alphabetical characters
                if (!isalpha(plaintext[c])) continue;

                plaintext[c] = isupper(plaintext[c])
                                   ? rotate(base_upper, rotation_upper, plaintext[c])
                                   : rotate(base_lower, rotation_lower, plaintext[c]);
        }
}

// WARNING: mutates 'ciphertext'!
void decipher_caesar(char key, size_t length, char ciphertext[length]) {
        caesar('Z' - (char) toupper(key) + 'A' + 1, length, ciphertext);
}


// WARNING: mutates 'plaintext'!
void vigenere(size_t key_len, const char key[key_len], size_t len, char plaintext[len]) {
        size_t key_index = 0;

        for (size_t c = 0; c < len; c++) {
                if (!isalpha(plaintext[c])) continue;

                while (!isalpha(key[key_index]))
                        key_index = (key_index + 1) % key_len;


                // mutates 'plaintext'!
                caesar(key[key_index], 1, plaintext + c);

                key_index = (key_index + 1) % key_len;
        }
}

// WARNING: mutates 'ciphertext'!
void decipher_vigenere(size_t key_len, const char key[key_len], size_t len, char ciphertext[len]) {
        size_t key_index = 0;

        for (size_t c = 0; c < len; c++) {
                if (!isalpha(ciphertext[c])) continue;

                while (!isalpha(key[key_index]))
                        key_index = (key_index + 1) % key_len;

                // mutates 'ciphertext'!
                decipher_caesar(key[key_index], 1, ciphertext + c);

                key_index = (key_index + 1) % key_len;
        }
}
