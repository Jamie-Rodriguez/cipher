#include "cipher_tests.h"


int main() {
        test_caesar_cipher_with_key_A();
        test_caesar_cipher_with_key_X();
        test_caesar_cipher_non_alphabetic();
        test_caesar_cipher_with_invalid_key();
        test_decipher_caesar();
        test_decipher_caesar_non_alphabetic();
        test_decipher_caesar_with_invalid_key();

        test_vigenere_cipher_non_alphabetic();
        test_vigenere_cipher_key_longer_than_plaintext();
        test_vigenere_cipher_with_non_alphabetic_in_key();
        test_decipher_vigenere();
        test_decipher_vigenere_non_alphabetic();
        test_decipher_vigenere_with_non_alphabetic_in_key();
}
