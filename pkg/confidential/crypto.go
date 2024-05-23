package confidential

import (
	"crypto/hmac"
	"crypto/sha256"
)

func HmacSHA256(key, data []byte) ([]byte, error) {
	h := hmac.New(sha256.New, key)
	if _, err := h.Write(data); err != nil {
		return nil, err
	}
	return h.Sum(nil), nil
}
