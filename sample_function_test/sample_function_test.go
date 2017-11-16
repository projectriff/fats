package sample_function_test

import (
	. "github.com/onsi/ginkgo"
	"github.com/pivotal-cf/pfs-system-test/util"
	"path"
	"github.com/onsi/gomega"
)

var _ = Describe("SampleFunctionTest", func() {
	Describe("SampleFunctionTest", func() {

		Context("deploy sample uppercase java function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "java", "greeter")

				functionName := util.RandStringShort()
				inputTopicName := util.RandStringShort()
				outputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/" + functionName

				util.MvnCleanPackage(functionDir)
				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)
				util.CLI("/", "topics-create", "-t", inputTopicName, "-ns", util.TEST_CONFIG.Namespace)
				util.CLI("/", "topics-create", "-t", outputTopicName, "-ns", util.TEST_CONFIG.Namespace)
				util.CLI("/", "-n", functionName, "push", "-i", inputTopicName, "-o", outputTopicName, "-ns", util.TEST_CONFIG.Namespace, "-m", imageName)
				util.SendMessageToGateway(inputTopicName, "World")

				outputMessage := util.KubectlFromKafkaPod(outputTopicName)
				gomega.Expect(outputMessage).To(gomega.MatchRegexp(`(?s:
.*contentType"application/octet-stream"spanId.*
spanTraceId.*spanParentSpanId.*
spanSampled.*spanName"` + inputTopicName + `:output.*Hello World.*)`))
			})
		})
	})
})
