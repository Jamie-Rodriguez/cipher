#include <rapidcheck.h>

extern "C" {
#include "cipher.h"
}


int main(const int argc, char const* argv[]) {
        rc::check(
            "Caesar: Encryption followed by decryption returns original text\n(decryption is the inverse of encryption)",
            [] {
                    const std::string plaintext =
                        *rc::gen::nonEmpty(rc::gen::string<std::string>());
                    const char key = *rc::gen::character<char>();
                    // Copy plaintext to modifiable buffer
                    std::string text = plaintext;

                    caesar(key, text.length(), text.data());
                    decipher_caesar(key, text.length(), text.data());

                    RC_ASSERT(text == plaintext);
            });

        rc::check(
            "Caesar: Rotating by 'A' returns original plaintext\n('A' is the identity element)",
            [] {
                    const std::string plaintext =
                        *rc::gen::nonEmpty(rc::gen::string<std::string>());
                    std::string text = plaintext;

                    caesar('A', text.length(), text.data());
                    RC_ASSERT(text == plaintext);
                    // Also test deciphering!
                    decipher_caesar('A', text.length(), text.data());
                    RC_ASSERT(text == plaintext);

                    // Test lowercase also
                    caesar('a', text.length(), text.data());
                    RC_ASSERT(text == plaintext);
                    decipher_caesar('a', text.length(), text.data());
                    RC_ASSERT(text == plaintext);
            });

        rc::check(
            "Caesar: Consecutive rotations are additive\n(Caesar cipher has the additive property)",
            [] {
                    const std::string plaintext =
                        *rc::gen::nonEmpty(rc::gen::string<std::string>());
                    /*
                      Make sure that the two generated keys are the same case.
                      It doesn't make sense to add a lowercase key to an uppercase
                      key; and you wouldn't know what kind of operation occurred
                      prior to calling `caesar()`
                    */
                    const bool uppercase = *rc::gen::arbitrary<bool>;
                    const auto isSameCase = uppercase
                                                ? [](char c) { return isalpha(c) && isupper(c); }
                                                : [](char c) { return isalpha(c) && islower(c); };
                    const char key1 = *rc::gen::suchThat<char>(isSameCase);
                    const char key2 = *rc::gen::suchThat<char>(isSameCase);
                    std::string cauchyForm = plaintext;
                    std::string compositeForm = plaintext;

                    caesar(key1, cauchyForm.length(), cauchyForm.data());
                    caesar(key2, cauchyForm.length(), cauchyForm.data());

                    const char compositeKey = (char) ((key1 + key2) % 26 + 'A');

                    caesar(compositeKey, compositeForm.length(), compositeForm.data());

                    RC_ASSERT(cauchyForm == compositeForm);

                    // Check this is also true for deciphering
                    decipher_caesar(key1, cauchyForm.length(), cauchyForm.data());
                    decipher_caesar(key2, cauchyForm.length(), cauchyForm.data());

                    decipher_caesar(compositeKey, compositeForm.length(), compositeForm.data());

                    RC_ASSERT(cauchyForm == compositeForm);
            });

        rc::check(
            "Vigenère: Encryption followed by decryption returns original text\n(decryption is the inverse of encryption)",
            [] {
                    const std::string plaintext =
                        *rc::gen::nonEmpty(rc::gen::string<std::string>());
                    const std::string key = *rc::gen::nonEmpty(rc::gen::string<std::string>());
                    std::string text = plaintext;

                    vigenere(key.length(), key.data(), text.length(), text.data());
                    decipher_vigenere(key.length(), key.data(), text.length(), text.data());

                    RC_ASSERT(text == plaintext);
            });

        rc::check("Vigenère: Single-character key is equivalent to Caesar cipher", [] {
                const std::string plaintext = *rc::gen::nonEmpty(rc::gen::string<std::string>());
                const char key = *rc::gen::suchThat<char>(isalpha);
                // Copy plaintext to modifiable buffer
                std::string caesarText = plaintext;
                std::string vigenereText = plaintext;

                caesar(key, caesarText.length(), caesarText.data());
                vigenere(1, &key, vigenereText.length(), vigenereText.data());
                RC_ASSERT(caesarText == vigenereText);

                decipher_caesar(key, caesarText.length(), caesarText.data());
                decipher_vigenere(1, &key, vigenereText.length(), vigenereText.data());
                RC_ASSERT(caesarText == vigenereText);
        });
}
