package sample_function_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("SampleFunctionTest", func() {
	Describe("SampleFunctionTest", func() {

		Context("the sun shines", func() {

			It("all is well", func() {
				Expect(true).To(BeTrue())
			})
		})
	})
})
