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
        REGISTRY_URL = "https://registry.hub.docker.com/"
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
                    println "Get status code ${env.STATUS_CODE} from container jenkins-docker-test"
                }
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( env.STATUS_CODE == "200" || env.STATUS_CODE == "403" || env.JENKINS_PASS != "" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry(env.REGISTRY_URL, env.REGISTRY_CREDENTIAL) {
                            println "Push image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}"
                            buildImage.push()
                            //if ( env.BRANCH_NAME == "master" ) {
                            //    println "Push image ${env.IMAGE_NAME}:master to registry ${env.REGISTRY_URL}"
                            //    buildImage.push("latest")
                            //} else {
                            //    println "Push image ${env.IMAGE_NAME}:${env.GIT_COMMIT_HASH} to registry ${env.REGISTRY_URL}"
                            //    buildImage.push(env.GIT_COMMIT_HASH)
                            //}
                        }
                        currentBuild.result = "SUCCESS"
                    } else {
                        println "Humans are mortals."
                        currentBuild.result = "FAILURE"
                    }
                }

            }
        }
        stage('Cleanup Image') {
            steps {
                script {
                    cleanupBuildImage()
                }
            }
        }
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
    echo "Get jenkins-docker-test container listening on http://${containerIP}:8080"
    env.STATUS_CODE = sh(returnStdout: true,
        script: """
            set +x
            curl -s -w \"%{http_code}\" -o /dev/null http://${containerIP}:8080
            """
    ).trim()
    env.JENKINS_PASS = sh(returnStdout: true,
        script: "docker exec -it jenkins-docker-test cat /var/jenkins_home/secrets/initialAdminPassword"
    ).trim()
}

def cleanupBuildImage() {
    sh "docker ps -q -f \"name=jenkins-docker-test\" | xargs --no-run-if-empty docker container stop"
    sh "docker container ls -a -q -f \"name=jenkins-docker-test\" | xargs -r docker container rm"
    sh "docker rmi ${env.IMAGE_NAME}"
}

def sendEmailNotification() {
    def emailTemplateDir = "/var/jenkins_home/email-templates"
    def emailTemplatePath = "${emailTemplateDir}/jk-email-template.html"

    sh "cp -f ${emailTemplatePath} ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${registryOrg}/${env.REGISTRY_ORG}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${registryRepo}/${env.REGISTRY_REPO}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${gitUrl}/${env.GIT_URL}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${gitBranch}/${env.GIT_BRANCH}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${gitCommitHash}/${env.GIT_COMMIT_HASH}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${gitCommitMsg}/${env.GIT_COMMIT_MESSAGE}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${gitCommitterName}/${env.GIT_COMMITTER_NAME}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${jobBaseName}/${env.JOB_BASE_NAME}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${buildNumber}/${env.BUILD_NUMBER}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${buildDuration}/${currentBuild.durationString}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${buildStatus}/${currentBuild.currentResult ? 'was broken' : 'passed'}/g\" ${emailTemplateDir}/jk-email.html"
    sh "sed -i \"s/\\${imgStatusSrc}/${currentBuild.currentResult ? 'passed' : 'failed'}/g\" ${emailTemplateDir}/jk-email.html"

    emailext mimeType: 'text/html',
        subject: "Jenkins build ${currentBuild.currentResult}: ${env.REGISTRY_ORG}/${env.REGISTRY_REPO}#${env.BUILD_NUMBER} (${env.GIT_BRANCH} - ${env.GIT_COMMIT_HASH})",
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
        //body: '${SCRIPT, template="groovy-html.template"}'
        body: '${FILE, path="${emailTemplateDir}/jk-email.html"}'

    sh "rm -f ${emailTemplateDir}/jk-email.html"
}

