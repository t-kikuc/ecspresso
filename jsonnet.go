package ecspresso

import (
	"fmt"
	"os"

	"github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
)

var DefaultJsonnetNativeFuncs = []*jsonnet.NativeFunction{
	JsonnetNativeEnvFunc,
	JsonnetNativeMustEnvFunc,
}

var JsonnetNativeEnvFunc = &jsonnet.NativeFunction{
	Name:   "env",
	Params: []ast.Identifier{"name", "default"},
	Func: func(args []interface{}) (interface{}, error) {
		if len(args) > 2 {
			return nil, fmt.Errorf("env: invalid number of arguments")
		}
		key, ok := args[0].(string)
		if !ok {
			return nil, fmt.Errorf("env: invalid argument type")
		}
		switch len(args) {
		case 1:
			return os.Getenv(key), nil
		case 2:
			if v := os.Getenv(key); v != "" {
				return v, nil
			}
			return args[1], nil
		}
		return nil, nil
	},
}

var JsonnetNativeMustEnvFunc = &jsonnet.NativeFunction{
	Name:   "must_env",
	Params: []ast.Identifier{"name"},
	Func: func(args []interface{}) (interface{}, error) {
		if len(args) > 1 {
			return nil, fmt.Errorf("must_env: invalid number of arguments")
		}
		key, ok := args[0].(string)
		if !ok {
			return nil, fmt.Errorf("must_env: invalid argument type")
		}
		if v, ok := os.LookupEnv(key); ok {
			return v, nil
		}
		return nil, fmt.Errorf("must_env: %s is not set", key)
	},
}
