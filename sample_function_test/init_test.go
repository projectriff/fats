package sample_function_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

func TestSampleFunction(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "sample_function")
}
