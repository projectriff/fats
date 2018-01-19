package util

import (
	"bytes"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var TEST_CONFIG = InitSystemTestConfig()

type SystemTestConfig struct {
	JavaInvokerVersion    string
	NodeInvokerVersion    string
	ShellInvokerVersion   string
	Python2InvokerVersion string
	Namespace             string
	KafkaPodName          string
	HTTPGatewayURL        string
	DockerOrg             string
	DockerUsername        string
	DockerPassword        string
	BaseDir               string
	MessageRTTimeout      int
}

func InitSystemTestConfig() SystemTestConfig {

	return SystemTestConfig{
		JavaInvokerVersion:    ensureEnv("SYS_TEST_JAVA_INVOKER_VERSION"),
		NodeInvokerVersion:    ensureEnv("SYS_TEST_NODE_INVOKER_VERSION"),
		ShellInvokerVersion:   ensureEnv("SYS_TEST_SHELL_INVOKER_VERSION"),
		Python2InvokerVersion: ensureEnv("SYS_TEST_PYTHON2_INVOKER_VERSION"),
		BaseDir:               ensureEnv("SYS_TEST_BASE_DIR"),
		Namespace:             ensureEnv("SYS_TEST_NS"),
		KafkaPodName:          ensureEnv("SYS_TEST_KAFKA_POD_NAME"),
		HTTPGatewayURL:        ensureEnv("SYS_TEST_HTTP_GW_URL"),
		DockerOrg:             ensureEnv("SYS_TEST_DOCKER_ORG"),
		DockerUsername:        ensureEnv("SYS_TEST_DOCKER_USERNAME"),
		DockerPassword:        ensureEnv("SYS_TEST_DOCKER_PASSWORD"),
		MessageRTTimeout:      ensureEnvInt("SYS_TEST_MSG_RT_TIMEOUT_SEC"),
	}
}

func ensureEnv(varName string) string {
	varValue := os.Getenv(varName)
	if varValue == "" {
		panic("Expected [" + varName + "] environment variable to be set")
	}
	return varValue
}
func ensureEnvInt(varName string) int {
	varValue := ensureEnv(varName)
	intValue, err := strconv.Atoi(varValue)
	if err != nil {
		panic("Couldn't parse [" + varName + "/" + varValue + "] as integer")
	}
	return intValue
}

func SendMessageToGateway(topic string, message string) {
	runSafely("Curl", "/", "curl", "-d", message, "-H", "Content-Type:text/plain", TEST_CONFIG.HTTPGatewayURL+"/messages/"+topic)
}

func SendRequestToGateway(topic string, message string) string {

	outBuffer := bytes.NewBufferString("")
	cmd := exec.Command("curl", "-d", message, "-H", "Content-Type:text/plain", TEST_CONFIG.HTTPGatewayURL+"/requests/"+topic)
	cmd.Stdout = outBuffer
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		panic("Curl for requests failed")
		cmd.Stderr.Write(outBuffer.Bytes())
	}

	return outBuffer.String()
}

func DeleteFile(path string) {
	os.Remove(path)
}

func CopyAndReplace(sourceFile string, destinationFile string, regexToMatch string, value string) {
	fileBytes, readErr := ioutil.ReadFile(sourceFile)
	if readErr != nil {
		panic("Failed to read file [" + sourceFile + "]" + readErr.Error())
	}
	sourceString := string(fileBytes)
	regex := regexp.MustCompile(regexToMatch)
	replacedString := string(regex.ReplaceAll([]byte(sourceString), []byte(value)))
	writeErr := ioutil.WriteFile(destinationFile, []byte(replacedString), os.ModePerm)
	if readErr != nil {
		panic("Failed to write file [" + destinationFile + "]" + writeErr.Error())
	}
}

func KubectlApply(workloadYamlPath string, namespace string) {
	runSafely("Kubectl Apply Workload", "/", "kubectl", "apply", "-n", namespace, "-f", workloadYamlPath)
}

func KubectlDelete(workloadYamlPath string, namespace string) {
	runSafely("Kubectl Delete Workload", "/", "kubectl", "delete", "-n", namespace, "-f", workloadYamlPath)
}

func KubectlDeleteFunction(functionName string, namespace string) {
	tryToRun("Delete function: " + functionName, "/", "kubectl", "delete", "-n", namespace, "function", functionName)
}

func KubectlFromKafkaPod(topic string) string {

	outBuffer := bytes.NewBufferString("")
	cmd := exec.Command("kubectl", "-n", TEST_CONFIG.Namespace, "exec", TEST_CONFIG.KafkaPodName, "--", "/opt/kafka/bin/kafka-console-consumer.sh", "--bootstrap-server", "localhost:9092", "--topic", topic, "--from-beginning", "--max-messages", "1")
	cmd.Stdout = outBuffer
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		panic("Kubectl Kafka start failed")
		cmd.Stderr.Write(outBuffer.Bytes())
	}
	timer := time.AfterFunc(time.Duration(TEST_CONFIG.MessageRTTimeout)*time.Second, func() {
		cmd.Process.Kill()
		panic("Kubectl Kafka timed out")
		cmd.Stderr.Write(outBuffer.Bytes())
	})
	err := cmd.Wait()
	timer.Stop()

	if err != nil {
		panic("Kubectl Kafka failed")
	}
	return outBuffer.String()
}

func RiffInit(baseDirectory string, contextDirectory string, fnName string, inputTopic string, artifactPath string, dockerUser string, dockerVersion string, riffInvokerVersion string) {
	runSafely("riff Init", baseDirectory, "./riff", "init", "-f", contextDirectory, "-n", fnName, "-i", inputTopic, "-a", artifactPath, "-u", dockerUser, "-v", dockerVersion, "--riff-version", riffInvokerVersion, "--force")
}

func RiffInitJava(baseDirectory string, contextDirectory string, fnName string, inputTopic string, outputTopic string, artifactPath string, className string, dockerUser string, dockerVersion string, riffInvokerVersion string) {
	runSafely("riff Init", baseDirectory, "./riff", "init", "-f", contextDirectory, "-n", fnName, "-i", inputTopic, "-o", outputTopic, "-a", artifactPath, "--handler", className, "--protocol", "pipes", "-u", dockerUser, "-v", dockerVersion, "--riff-version", riffInvokerVersion, "--force")
}

func RiffInitPy(baseDirectory string, contextDirectory string, fnName string, inputTopic string, artifactPath string, handler string, dockerUser string, dockerVersion string, riffInvokerVersion string) {
	runSafely("riff Init", baseDirectory, "./riff", "init", "-f", contextDirectory, "-n", fnName, "-i", inputTopic, "-a", artifactPath, "--handler", handler, "-u", dockerUser, "-v", dockerVersion, "--riff-version", riffInvokerVersion, "--force")
}

func DockerBuild(contextDirectory string, imageName string) {
	runSafely("Docker Build", "/", "docker", "build", contextDirectory, "-t", imageName)
}

func DockerPush(imageName string) {
	runSafely("Docker Login", "/", "docker", "login", "-u", TEST_CONFIG.DockerUsername, "-p", TEST_CONFIG.DockerPassword)
	runSafely("Docker Push", "/", "docker", "push", imageName)
}

func DockerTagAndPush(functionName string, imageName string) {

	outBuffer := bytes.NewBufferString("")
	dockerCmd := exec.Command("docker", "images", "-f", "reference="+functionName, "--format", "{{.ID}}")
	dockerCmd.Stdout = outBuffer
	dockerCmd.Stderr = os.Stderr
	err := dockerCmd.Run()
	if err != nil {
		panic("Docker image list failed")
		dockerCmd.Stderr.Write(outBuffer.Bytes())
	}

	runSafely("Docker Tag", "/", "docker", "tag", strings.TrimSpace(outBuffer.String()), imageName)
	runSafely("Docker Login", "/", "docker", "login", "-u", TEST_CONFIG.DockerUsername, "-p", TEST_CONFIG.DockerPassword)
	runSafely("Docker Push", "/", "docker", "push", imageName)
}

func MvnCleanPackage(directory string) {
	runSafely("Maven Build", directory, "./mvnw", "clean", "package")
}

func Run(directory string, command string, args ...string) {
	runSafely("Run ["+command+"]", directory, command, args...)
}

func runSafely(description string, directory string, command string, args ...string) {
	cmd := exec.Command(command, args...)
	cmd.Dir = directory
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		panic(description + " failed in directory " + directory)
	}
}

func tryToRun(description string, directory string, command string, args ...string) {
	cmd := exec.Command(command, args...)
	cmd.Dir = directory
	cmd.Stdout = nil
	cmd.Stderr = nil
	err := cmd.Run()
	if err != nil {
		println(description + " - not found")
	}
}

const letters = "abcdefghijklmnopqrstuvwxyz"

func RandStringShort() string {
	return randString(8)
}

func RandStringLong() string {
	return randString(24)
}

func randString(n int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
