package sample_function_test

import (
	"path"

	. "github.com/onsi/ginkgo"
	"github.com/onsi/gomega"
	"github.com/pivotal-cf/pfs-system-test/util"
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
				imageName := util.TEST_CONFIG.DockerOrg + "/"+functionName+":"+dockerTag
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.MvnCleanPackage(functionDir)

				util.RiffInitJava(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, outputTopicName, "target/greeter-1.0.0.jar", "functions.Greeter", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.JavaInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)

				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.SendMessageToGateway(inputTopicName, "World")

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
				functionName := "sys-test-square"
				inputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/"+functionName+":"+dockerTag
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInit(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "square.js", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.NodeInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)

				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				reply := util.SendRequestToGateway(inputTopicName, "12")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*144.*)`))

				util.KubectlDelete(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFile)
				util.DeleteFile(topicWorkloadFile)
			})
		})

		Context("deploy sample sentiments python function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "python", "sentiments")

				dockerTag := util.RandStringShort()
				functionName := "sys-test-sentiments"
				inputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/"+functionName+":"+dockerTag
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInitPy(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "sentiment_service.py", "process", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.Python2InvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)

				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)

				reply := util.SendRequestToGateway(inputTopicName, "[{\"text\":\"happy happy happy\"},{\"text\":\"sad sad sad\"}]")

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
				imageName := util.TEST_CONFIG.DockerOrg + "/"+functionName+":"+dockerTag
				fnWorkloadFile := path.Join(functionDir, functionName+"-function.yaml")
				topicWorkloadFile := path.Join(functionDir, functionName+"-topics.yaml")

				// just in case there is already a function with the same name
				util.KubectlDeleteFunction(functionName, util.TEST_CONFIG.Namespace)

				util.RiffInit(util.TEST_CONFIG.BaseDir, functionDir, functionName, inputTopicName, "echo.sh", util.TEST_CONFIG.DockerOrg, dockerTag, util.TEST_CONFIG.ShellInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)

				util.KubectlApply(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlApply(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				reply := util.SendRequestToGateway(inputTopicName, "fooo")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*fooo.*)`))

				util.KubectlDelete(fnWorkloadFile, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFile, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFile)
				util.DeleteFile(topicWorkloadFile)
			})
		})
	})
})
