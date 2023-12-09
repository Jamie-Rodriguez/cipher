#ifndef CIPHER_H
#define CIPHER_H

#include <stddef.h>


// NOTE: All ciphers assume 'plaintext'/'ciphertext' is all uppercase ASCII
//       characters i.e. 'A' - 'Z'

// WARNING: mutates 'plaintext'!
void caesar(char key, size_t length, char plaintext[length]);
// WARNING: mutates 'ciphertext'!
void decipher_caesar(char key, size_t length, char ciphertext[length]);
// WARNING: mutates 'plaintext'!
void vigenere(size_t key_len, const char key[key_len], size_t len, char plaintext[len]);
// WARNING: mutates 'ciphertext'!
void decipher_vigenere(size_t key_len, const char key[key_len], size_t len, char ciphertext[len]);

#endif
