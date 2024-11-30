#ifndef CIPHER_TESTS_H
#define CIPHER_TESTS_H


void test_caesar_cipher_with_key_A(void);
void test_caesar_cipher_with_key_X(void);
void test_caesar_cipher_non_alphabetic(void);
void test_caesar_cipher_with_invalid_key(void);
void test_decipher_caesar(void);
void test_decipher_caesar_non_alphabetic(void);
void test_decipher_caesar_with_invalid_key(void);

void test_vigenere_cipher_non_alphabetic(void);
void test_vigenere_cipher_key_longer_than_plaintext(void);
void test_vigenere_cipher_with_non_alphabetic_in_key(void);
void test_decipher_vigenere(void);
void test_decipher_vigenere_non_alphabetic(void);
void test_decipher_vigenere_with_non_alphabetic_in_key(void);


#endif
