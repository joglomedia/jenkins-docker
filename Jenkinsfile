/**
 * Jenkins Pipeline
 * Ref:
 *  https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *  https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */
pipeline {
    agent any
    environment {
        REGISTRY_ORG = "eslabsid"
        REGISTRY_REPO = "jenkins-docker"
        REGISTRY_URL = "https://index.docker.io/v1/"
        REGISTRY_CREDENTIAL = "dockerhub-cred"
    }
    stages {
        stage('Init') {
            steps {
                script {
                    env.GIT_COMMIT_HASH = sh(returnStdout: true,
                        script: "git log --oneline -1 ${env.GIT_COMMIT} | head -1 | cut -d' ' -f1",
                    ).trim()
                    env.GIT_COMMIT_MESSAGE = sh(returnStdout: true,
                        script: "git log --oneline -1 ${env.GIT_COMMIT} | head -1 | cut -d')' -f1",
                    ).trim()
                    env.IMAGE_NAME = "${env.REGISTRY_ORG}/${env.REGISTRY_REPO}:" + ((env.BRANCH_NAME == "master") ? "latest" : env.GIT_COMMIT_HASH)
                    env.GIT_COMMITTER_EMAIL = sh(returnStdout: true,
                        script: "git log --oneline --format=\"%ae\" ${env.GIT_COMMIT} | head -1",
                    ).trim()
                    println "Commit ${env.GIT_COMMIT_HASH} checked out from ${env.BRANCH_NAME} branch"
                }
            }
        }
        stage('Build Image') {
            steps {
                script {
                    def buildImage = docker.build(env.IMAGE_NAME)
                    if ( buildImage.id != "" ) {
                        println "Docker image ${buildImage.id} built from commit ${env.GIT_COMMIT_HASH}"
                    } else {
                        println "Failed building Docker image ${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage('Test Image') {
            steps {
                script {
                    testBuildImage()
                }
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( env.STATUS_CODE != "000" || env.JENKINS_PASS != "" ) {
                        println "Jenkins-docker is alive and kicking!"
                        withDockerRegistry(credentialsId: "${env.REGISTRY_CREDENTIAL}", url: "") {
                            println "Push image ${env.IMAGE_NAME} to DockerHub registry"
                            //buildImage.push()
                            sh "docker push ${env.IMAGE_NAME}"
                            sh "docker logout"
                        }
                        currentBuild.result = "SUCCESS"
                    } else {
                        println "Humans are mortals."
                        currentBuild.result = "FAILURE"
                    }
                }

            }
        }
        /*stage('Cleanup Image') {
            steps {
                script {
                    cleanupBuildImage()
                }
            }
        }*/
    }
    post {
        always {
            script {
                cleanupBuildImage()
                sendEmailNotification()
            }
            cleanWs()
        }
    }
}


def testBuildImage() {
    sh "docker container run -d --name=jenkins-docker-test -p 49001:8080 -v /var/run/docker.sock:/var/run/docker.sock ${env.IMAGE_NAME}"
    sleep(time:10,unit:"SECONDS")

    def containerIP = sh(returnStdout: true,
        script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' jenkins-docker-test"
    ).trim()
    echo "Run jenkins-docker-test container listening on http://${containerIP}:8080"

    env.STATUS_CODE = sh(returnStdout: true,
        script: """
            set +x
            curl -s -w \"%{http_code}\" -o /dev/null http://${containerIP}:8080
            """
    ).trim()
    println "Get status code ${env.STATUS_CODE} from container jenkins-docker-test"

    /*
    env.JENKINS_PASS = sh(returnStdout: true,
        script: "docker exec -i jenkins-docker-test cat /var/jenkins_home/secrets/initialAdminPassword"
    ).trim()
    if ( env.JENKINS_PASS != "" ) {
        println "Get initial admin password ${env.JENKINS_PASS} from container jenkins-docker-test"
    }
    */
}

def cleanupBuildImage() {
    sleep(time:10,unit:"SECONDS")
    sh "docker ps -qf \"name=jenkins-docker-test\" | xargs --no-run-if-empty docker container stop"
    sh "docker container ls -aqf \"name=jenkins-docker-test\" | xargs --no-run-if-empty docker container rm"
    sh "docker images -q ${env.IMAGE_NAME} | xargs --no-run-if-empty docker rmi"
    sh "docker system prune --force"
}

def sendEmailNotification() {
    def emailTemplateDir = "/var/jenkins_home/email-templates"
    def emailTemplatePath = "${emailTemplateDir}/jk-email-template.html"
    def rgitUrl = "${env.GIT_URL}"
    def gitUrl = rgitUrl.replace(".get", "")
    def gitCommiterEmail = "${env.GIT_COMMITTER_EMAIL}"
    def gitCommitterAvatar = sh(returnStdout: true,
        script: """
            md5sum <<<${env.GIT_COMMITTER_EMAIL}
            """
    ).trim()
    def buildStatus = ((currentBuild.currentResult == '' || currentBuild.currentResult == 'SUCCESS') ? 'passed' : (currentBuild.currentResult == 'FAILURE') ? 'failed' : 'warning')
    def cssBgColor = ((currentBuild.currentResult == '' || currentBuild.currentResult == 'SUCCESS') ? '#db4545' : '#32d282')
    
    sh "cp -f ${emailTemplatePath} ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{registryOrg}|${env.REGISTRY_ORG}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{registryRepo}|${env.REGISTRY_REPO}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitUrl}|${gitUrl}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitBranch}|${env.BRANCH_NAME}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitCommitHash}|${env.GIT_COMMIT_HASH}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitCommitMsg}|${env.GIT_COMMIT_MESSAGE}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitCommitterName}|${env.GIT_COMMITTER_NAME}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{gitCommitterAvatar}|${gitCommitterAvatar}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{jobBaseName}|${env.JOB_BASE_NAME}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{jobName}|${env.JOB_NAME}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{buildUrl}|${env.BUILD_URL}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{buildNumber}|${env.BUILD_NUMBER}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{buildDuration}|${currentBuild.durationString}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{buildStatus}|${buildStatus}|g' ${emailTemplateDir}/jk-email.html"
    sh "sed -i 's|{cssBgColor}|${cssBgColor}|g' ${emailTemplateDir}/jk-email.html"

    emailext mimeType: 'text/html',
        subject: "Jenkins build ${currentBuild.currentResult}: ${env.REGISTRY_ORG}/${env.REGISTRY_REPO}#${env.BUILD_NUMBER} (${env.GIT_BRANCH} - ${env.GIT_COMMIT_HASH})",
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
        //body: '${SCRIPT, template="groovy-html.template"}'
        body: '${FILE, path="jk-email.html"}'

    sh "rm -f ${emailTemplateDir}/jk-email.html"
}
