package sample_function_test

import (
	"path"

	. "github.com/onsi/ginkgo"
	"github.com/onsi/gomega"
	"github.com/projectriff/fats/util"
)

var _ = Describe("SampleFunctionTest", func() {
	Describe("SampleFunctionTest", func() {

		Context("deploy sample greeter java function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "java", "greeter")

				dockerTag := util.RandStringShort()
				functionName := "sys-test-greeter"
				inputTopicName := util.RandStringShort()
				outputTopicName := util.RandStringShort()
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.MvnCleanPackage(functionDir)

				util.RiffInitJava(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, outputTopicName, "target/greeter-1.0.0.jar", "functions.Greeter", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.JavaInvokerVersion)

				util.RiffBuildAndPush(util.TEST_CONFIG.BaseDir, functionDir,functionName, util.TEST_CONFIG.DockerOrg, dockerTag)

				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)

				util.RiffPublishMessage(util.TEST_CONFIG.BaseDir, inputTopicName, "World")

				outputMessage := util.KubectlFromKafkaPod(outputTopicName)
				gomega.Expect(outputMessage).To(gomega.MatchRegexp(`(?s:.*Hello World.*)`))

				util.KubectlDelete(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFile)
				util.DeleteFile(topicWorkloadFile)
			})
		})

		Context("deploy sample square node function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "node", "square")

				dockerTag := util.RandStringShort()
				functionName := "node-sample-image"
				inputTopicName := functionName

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInit(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "square.js", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.NodeInvokerVersion)
				util.RiffApply(util.TEST_CONFIG.BaseDir, functionDir)

				reply := util.RiffPublishMessageWithReply(util.TEST_CONFIG.BaseDir, inputTopicName, "12")
				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*144.*)`))
			})
		})

		Context("deploy sample sentiments python function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "python", "sentiments")

				dockerTag := util.RandStringShort()
				functionName := "sys-test-sentiments"
				inputTopicName := util.RandStringShort()
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInitPy(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "sentiment_service.py", "process", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.Python2InvokerVersion)

				util.RiffBuildAndPush(util.TEST_CONFIG.BaseDir, functionDir,functionName, util.TEST_CONFIG.DockerOrg, dockerTag)

				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)

				reply := util.RiffPublishMessageWithReply(util.TEST_CONFIG.BaseDir, inputTopicName, "[{\"text\":\"happy happy happy\"},{\"text\":\"sad sad sad\"}]")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*happy happy happy.*)`))
				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*sad sad sad.*)`))

				util.KubectlDelete(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFile)
				util.DeleteFile(topicWorkloadFile)
			})
		})

		Context("deploy sample echo shell function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "shell", "echo")

				dockerTag := util.RandStringShort()
				functionName := "sys-test-echo"
				inputTopicName := util.RandStringShort()
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInit(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "echo.sh", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.ShellInvokerVersion)

				util.RiffBuildAndPush(util.TEST_CONFIG.BaseDir, functionDir,functionName, util.TEST_CONFIG.DockerOrg, dockerTag)

				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)

				reply := util.RiffPublishMessageWithReply(util.TEST_CONFIG.BaseDir, inputTopicName, "fooo")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*fooo.*)`))

				util.KubectlDelete(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFile)
				util.DeleteFile(topicWorkloadFile)
			})
		})
	})
})
