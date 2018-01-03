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

				functionName := util.RandStringShort()
				inputTopicName := util.RandStringShort()
				outputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/testjavagreeter:" + functionName
				workloadFileSource := path.Join(functionDir, "greeter.yaml")
				workloadFileTarget := path.Join(functionDir, functionName+".yaml")

				util.MvnCleanPackage(functionDir)
				util.CopyAndReplace(path.Join(functionDir, "Dockerfile"), path.Join(functionDir, "Dockerfile"), "java-function-invoker:.*", "java-function-invoker:"+util.TEST_CONFIG.JavaInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)
				util.CopyAndReplace(workloadFileSource, workloadFileTarget, "name: greeter", "name: "+functionName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "name: names", "name: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "name: greetings", "name: "+outputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "input: names", "input: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "output: greetings", "output: "+outputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "protocol: http", "protocol: pipes")
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "image: projectriff/greeter:.*", "image: "+imageName)

				util.KubectlApply(workloadFileTarget, util.TEST_CONFIG.Namespace)
				util.SendMessageToGateway(inputTopicName, "World")

				outputMessage := util.KubectlFromKafkaPod(outputTopicName)
				gomega.Expect(outputMessage).To(gomega.MatchRegexp(`(?s:.*Hello World.*)`))

				util.KubectlDelete(workloadFileTarget, util.TEST_CONFIG.Namespace)
				util.DeleteFile(workloadFileTarget)
			})
		})

		Context("deploy sample square node function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "node", "square")

				functionName := util.RandStringShort()
				inputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/testnodesquare:" + functionName
				workloadFileSource := path.Join(functionDir, "square.yaml")
				workloadFileTarget := path.Join(functionDir, functionName+".yaml")

				util.CopyAndReplace(path.Join(functionDir, "Dockerfile"), path.Join(functionDir, "Dockerfile"), "node-function-invoker:.*", "node-function-invoker:"+util.TEST_CONFIG.NodeInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)
				util.CopyAndReplace(workloadFileSource, workloadFileTarget, "name: square", "name: "+functionName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "name: numbers", "name: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "input: numbers", "input: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "image: projectriff/square:.*", "image: "+imageName)

				util.KubectlApply(workloadFileTarget, util.TEST_CONFIG.Namespace)
				reply := util.SendRequestToGateway(inputTopicName, "12")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*144.*)`))

				util.KubectlDelete(workloadFileTarget, util.TEST_CONFIG.Namespace)
				util.DeleteFile(workloadFileTarget)
			})
		})

		Context("deploy sample uppercase python function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "python", "uppercase")

				functionName := util.RandStringShort()
				inputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/testpythonupper:" + functionName
				workloadFileSource := path.Join(functionDir, "uppercase.yaml")
				workloadFileTarget := path.Join(functionDir, functionName+".yaml")

				customDockerize := "dockerize" + functionName
				util.CopyAndReplace(path.Join(functionDir, "dockerize"), path.Join(functionDir, customDockerize), "docker build", " # docker build")
				util.Run(functionDir, "bash", path.Join(functionDir, customDockerize))

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)
				util.CopyAndReplace(workloadFileSource, workloadFileTarget, "name: uppercase", "name: "+functionName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "name: greetings", "name: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "input: greetings", "input: "+inputTopicName)
				util.CopyAndReplace(workloadFileTarget, workloadFileTarget, "image: projectriff/grpc-py:.*", "image: "+imageName)

				util.KubectlApply(workloadFileTarget, util.TEST_CONFIG.Namespace)
				reply := util.SendRequestToGateway(inputTopicName, "foobar")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*FOOBAR.*)`))

				util.KubectlDelete(workloadFileTarget, util.TEST_CONFIG.Namespace)
				util.DeleteFile(workloadFileTarget)
				util.DeleteFile(customDockerize)
			})
		})

		Context("deploy sample echo shell function", func() {

			It("builds and deploys", func() {
				functionDir := path.Join(util.TEST_CONFIG.BaseDir, "samples", "shell", "echo")

				functionName := util.RandStringShort()
				inputTopicName := util.RandStringShort()
				imageName := util.TEST_CONFIG.DockerOrg + "/testshellecho:" + functionName
				topicWorkloadFileSource := path.Join(functionDir, "greetings-topic.yaml")
				topicWorkloadFileTarget := path.Join(functionDir, functionName+"-topic.yaml")
				fnWorkloadFileSource := path.Join(functionDir, "echo-function.yaml")
				fnWorkloadFileTarget := path.Join(functionDir, functionName+".yaml")

				util.CopyAndReplace(path.Join(functionDir, "Dockerfile"), path.Join(functionDir, "Dockerfile"), "shell-function-invoker:.*", "shell-function-invoker:"+util.TEST_CONFIG.ShellInvokerVersion)

				util.DockerBuild(functionDir, imageName)
				util.DockerPush(imageName)

				util.CopyAndReplace(topicWorkloadFileSource, topicWorkloadFileTarget, "name: greetings", "name: "+inputTopicName)

				util.CopyAndReplace(fnWorkloadFileSource, fnWorkloadFileTarget, "name: echo", "name: "+functionName)
				util.CopyAndReplace(fnWorkloadFileTarget, fnWorkloadFileTarget, "input: greetings", "input: "+inputTopicName)
				util.CopyAndReplace(fnWorkloadFileTarget, fnWorkloadFileTarget, "image: projectriff/echo:.*", "image: "+imageName)

				util.KubectlApply(topicWorkloadFileTarget, util.TEST_CONFIG.Namespace)
				util.KubectlApply(fnWorkloadFileTarget, util.TEST_CONFIG.Namespace)
				reply := util.SendRequestToGateway(inputTopicName, "fooo")

				gomega.Expect(reply).To(gomega.MatchRegexp(`(?s:.*fooo.*)`))

				util.KubectlDelete(fnWorkloadFileTarget, util.TEST_CONFIG.Namespace)
				util.KubectlDelete(topicWorkloadFileTarget, util.TEST_CONFIG.Namespace)
				util.DeleteFile(fnWorkloadFileTarget)
				util.DeleteFile(topicWorkloadFileTarget)
			})
		})
	})
})
