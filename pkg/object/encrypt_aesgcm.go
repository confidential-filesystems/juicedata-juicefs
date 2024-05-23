/*
 * JuiceFS, Copyright 2020 Juicedata, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package object

import (
	"crypto/cipher"
	"crypto/rand"
	"errors"
	"fmt"
	"io"

	"github.com/juicedata/juicefs/pkg/confidential"
)

// AESGCM
type aecgcmEncryptor struct {
	privKey []byte
	aead    func(key []byte) (cipher.AEAD, error)
	label   []byte
}

func NewAESGCMEncryptor(privKey []byte, aead func(key []byte) (cipher.AEAD, error)) Encryptor {
	return &aecgcmEncryptor{privKey, aead, []byte("keys")}
}

func (e *aecgcmEncryptor) Encrypt(prefix string, nonce []byte, plaintext []byte) ([]byte, error) {
	//logger.Infof("aecgcmEncryptor.Encrypt(): prefix = %v", prefix)
	//return rsa.EncryptOAEP(sha256.New(), rand.Reader, &e.privKey.PublicKey, plaintext, e.label)
	kek, err := e.getKek(prefix)
	if err != nil {
		return nil, err
	}
	aead, err := e.aead(kek)
	if err != nil {
		return nil, err
	}
	buf := make([]byte, len(plaintext)+aead.Overhead())
	ciphertext := aead.Seal(buf[:0], nonce, plaintext, nil)
	return ciphertext, nil
}

func (e *aecgcmEncryptor) Decrypt(prefix string, nonce []byte, ciphertext []byte) ([]byte, error) {
	//logger.Infof("aecgcmEncryptor.Decrypt(): prefix = %v", prefix)
	//return rsa.DecryptOAEP(sha256.New(), rand.Reader, e.privKey, ciphertext, e.label)
	kek, err := e.getKek(prefix)
	if err != nil {
		return nil, err
	}
	aead, err := e.aead(kek)
	if err != nil {
		return nil, err
	}
	return aead.Open(ciphertext[:0], nonce, ciphertext, nil)
}

func (e *aecgcmEncryptor) getKek(prefix string) ([]byte, error) {
	key := "Filesystem KEK of " + prefix
	data := e.privKey
	return confidential.HmacSHA256(([]byte)(key), data)
}

type aesgcmDataEncryptor struct {
	keyEncryptor Encryptor
	keyLen       int
	aead         func(key []byte) (cipher.AEAD, error)
}

func (e *aesgcmDataEncryptor) Encrypt(prefix string, nonce []byte, plaintext []byte) ([]byte, error) {
	//logger.Infof("aesgcmDataEncryptor.Encrypt(): prefix = %v", prefix)
	key := make([]byte, e.keyLen)
	if _, err := io.ReadFull(rand.Reader, key); err != nil {
		return nil, err
	}
	aead, err := e.aead(key)
	if err != nil {
		return nil, err
	}
	nonce = make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}
	cipherkey, err := e.keyEncryptor.Encrypt(prefix, nonce, key)
	if err != nil {
		return nil, err
	}

	headerSize := 3 + len(cipherkey) + len(nonce)
	buf := make([]byte, headerSize+len(plaintext)+aead.Overhead())
	buf[0] = byte(len(cipherkey) >> 8)
	buf[1] = byte(len(cipherkey) & 0xFF)
	buf[2] = byte(len(nonce))
	p := buf[3:]
	copy(p, cipherkey)
	p = p[len(cipherkey):]
	copy(p, nonce)
	p = p[len(nonce):]
	ciphertext := aead.Seal(p[:0], nonce, plaintext, nil)
	return buf[:headerSize+len(ciphertext)], nil
}

func (e *aesgcmDataEncryptor) Decrypt(prefix string, nonce []byte, ciphertext []byte) ([]byte, error) {
	//logger.Infof("aesgcmDataEncryptor.Decrypt(): prefix = %v", prefix)
	keyLen := int(ciphertext[0])<<8 + int(ciphertext[1])
	nonceLen := int(ciphertext[2])
	if 3+keyLen+nonceLen >= len(ciphertext) {
		return nil, fmt.Errorf("misformed ciphertext: %d %d", keyLen, nonceLen)
	}
	ciphertext = ciphertext[3:]
	cipherkey := ciphertext[:keyLen]
	nonce = ciphertext[keyLen : keyLen+nonceLen]
	ciphertext = ciphertext[keyLen+nonceLen:]

	key, err := e.keyEncryptor.Decrypt(prefix, nonce, cipherkey)
	if err != nil {
		return nil, errors.New("decryt key: " + err.Error())
	}
	aead, err := e.aead(key)
	if err != nil {
		return nil, err
	}
	return aead.Open(ciphertext[:0], nonce, ciphertext, nil)
}
