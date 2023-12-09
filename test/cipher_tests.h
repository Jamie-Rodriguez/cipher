#ifndef CIPHER_TESTS_H
#define CIPHER_TESTS_H


void test_caesar_cipher_with_key_A();
void test_caesar_cipher_with_key_X();
void test_caesar_cipher_non_alphabetic();
void test_caesar_cipher_with_invalid_key();
void test_decipher_caesar();
void test_decipher_caesar_non_alphabetic();
void test_decipher_caesar_with_invalid_key();

void test_vigenere_cipher_non_alphabetic();
void test_vigenere_cipher_key_longer_than_plaintext();
void test_vigenere_cipher_with_non_alphabetic_in_key();
void test_decipher_vigenere();
void test_decipher_vigenere_non_alphabetic();
void test_decipher_vigenere_with_non_alphabetic_in_key();


#endif
