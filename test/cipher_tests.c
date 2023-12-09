#include "cipher.h"
#include <assert.h>
#include <string.h>


void test_caesar_cipher_with_key_A() {
        char plaintext[] = "THEQUICKBROWNFOXJUMPSOVERTHELAZYDOG";

        caesar('A', strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "THEQUICKBROWNFOXJUMPSOVERTHELAZYDOG") == 0 &&
               "Caesar cipher with key 'A' failed");
}

void test_caesar_cipher_with_key_X() {
        char plaintext[] = "THEQUICKBROWNFOXJUMPSOVERTHELAZYDOG";

        caesar('X', strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "QEBNRFZHYOLTKCLUGRJMPLSBOQEBIXWVALD") == 0 &&
               "Caesar cipher with key 'X' failed");
}

void test_caesar_cipher_non_alphabetic() {
        char plaintext[] = "Hello, World!";

        caesar('J', strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "Qnuux, Fxaum!") == 0 &&
               "Caesar cipher on plaintext containing non-alphanumeric characters failed");
}

void test_caesar_cipher_with_invalid_key() {
        char plaintext[] = "I SHOULD NOT CHANGE BECAUSE THE KEY IS INVALID!";

        caesar('.', strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "I SHOULD NOT CHANGE BECAUSE THE KEY IS INVALID!") == 0 &&
               "Caesar cipher with invalid key failed");
}

void test_decipher_caesar() {
        char ciphertext[] = "ZSSZBJZSNMBD";

        decipher_caesar('Z', strlen(ciphertext), ciphertext);

        assert(strcmp(ciphertext, "ATTACKATONCE") == 0 && "Deciphering Caesar cipher failed");
}

void test_decipher_caesar_non_alphabetic() {
        char ciphertext[] = "QNUUX, FXAUM!";

        decipher_caesar('J', strlen(ciphertext), ciphertext);

        assert(
            strcmp(ciphertext, "HELLO, WORLD!") == 0 &&
            "Deciphering Caesar cipher on ciphertext containing non-alphabetic characters failed");
}

void test_decipher_caesar_with_invalid_key() {
        char ciphertext[] = "UNCHANGEDCIPHERTEXT";

        decipher_caesar('!', strlen(ciphertext), ciphertext);

        assert(strcmp(ciphertext, "UNCHANGEDCIPHERTEXT") == 0 &&
               "Deciphering Caesar cipher with invalid key failed");
}


void test_vigenere_cipher_non_alphabetic() {
        char plaintext[] = "As we wind on down the road, our shadows taller than our souls...";
        const char* key = "Led Zeppelin";

        vigenere(strlen(key), key, strlen(plaintext), plaintext);

        assert(strcmp(plaintext,
                      "Lw zd axch zv qzaq slt gsll, bfv vgesdad bnwphq xwpr zce dsxkw...") == 0 &&
               "Vigenère cipher on plaintext containing non-alphabetic characters failed");
}

void test_vigenere_cipher_key_longer_than_plaintext() {
        char plaintext[] = "TEXT";
        const char* key = "LONGKEY";

        vigenere(strlen(key), key, strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "ESKZ") == 0 &&
               "Vigenère cipher with key longer than plaintext failed");
}

void test_vigenere_cipher_with_non_alphabetic_in_key() {
        char plaintext[] = "Quality is not an act, it is a habit.";
        const char* key = "I'm a key!";

        vigenere(strlen(key), key, strlen(plaintext), plaintext);

        assert(strcmp(plaintext, "Ygavmrg us xsr iz amx, gb us k lyjut.") == 0 &&
               "Vigenère cipher with non-alphabetic char in key failed");
}

void test_decipher_vigenere() {
        char ciphertext[] = "GFNJCE CRLRG SOI AOR";
        const char* key = "ARAGON";

        decipher_vigenere(strlen(key), key, strlen(ciphertext), ciphertext);

        assert(strcmp(ciphertext, "GONDOR CALLS FOR AID") == 0 &&
               "Deciphering Vigenère cipher failed");
}

void test_decipher_vigenere_non_alphabetic() {
        char ciphertext[] = "QLIDBHR TW NFB SG OVE, MT ZA S AOUTX.";

        const char* key = "ARISTOTLE";

        decipher_vigenere(strlen(key), key, strlen(ciphertext), ciphertext);
        assert(strcmp(ciphertext, "QUALITY IS NOT AN ACT, IT IS A HABIT.") == 0 &&
               "Deciphering Vigenère cipher with non-alphabetic char in ciphertext failed");
}

void test_decipher_vigenere_with_non_alphabetic_in_key() {
        char ciphertext[] = "Qz tri jizd yj rpq bvmll, fho slm-qyoh kiz ic ogvs.";
        const char* key = "I'm a key!";

        decipher_vigenere(strlen(key), key, strlen(ciphertext), ciphertext);

        assert(strcmp(ciphertext, "In the land of the blind, the one-eyed man is king.") == 0 &&
               "Deciphering Vigenère cipher with non-alphabetic char in key failed");
}
