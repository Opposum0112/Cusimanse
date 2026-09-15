package capability

import "errors"

var (
	ErrInvalidCapability   = errors.New("invalid capability")
	ErrDuplicateCapability = errors.New("duplicate capability")
)
