/**
 * Jenkins Pipeline
 * Ref:
 *  https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *  https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */
def customImage
pipeline {
    agent any
    environment {
        REGISTRY_ORG = "eslabsid"
        REGISTRY_REPO = "jenkins-docker"
        REGISTRY_URL = "https://registry.hub.docker.com" // https://index.docker.io/v1/
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

                    env.GIT_COMMITTER_EMAIL = sh(returnStdout: true,
                        script: "git log --oneline --format=\"%ae\" ${env.GIT_COMMIT} | head -1",
                    ).trim()

                    env.GIT_COMMITTER_NAME = sh(returnStdout: true,
                        script: "git log --oneline --format=\"%an\" ${env.GIT_COMMIT} | head -1",
                    ).trim()

                    env.IMAGE_NAME = "${env.REGISTRY_ORG}/${env.REGISTRY_REPO}:" + ((env.BRANCH_NAME == "master") ? "latest" : env.GIT_COMMIT_HASH)
                }
                echo "Commit ${env.GIT_COMMIT_HASH} checked out from ${env.BRANCH_NAME} branch"
            }
        }
        stage('Build Image') {
            steps {
                script {
                    customImage = docker.build(env.IMAGE_NAME)
                    if ( customImage.id != "" ) {
                        echo "Docker image ${customImage.id} built from commit ${env.GIT_COMMIT_HASH}"
                    } else {
                        echo "Failed building Docker image ${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage('Test Image') {
            steps {
                script {
                    env.STATUS_CODE = runCustomImage(customImage)
                    env.JENKINS_PASS = getInitialAdminPassword()
                }
                echo "Get status code ${env.STATUS_CODE} from custom image container"
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( env.STATUS_CODE == "200" || env.STATUS_CODE == "403" || env.JENKINS_PASS != "" ) {
                        echo "Jenkins-docker is alive and kicking!"
                        withDockerRegistry(credentialsId: "${env.REGISTRY_CREDENTIAL}", url: "${env.REGISTRY_URL}") {
                            echo "Pushing custom Docker image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}"
                            sh "docker push ${env.IMAGE_NAME}"
                            sh "docker logout"
                        }
                        currentBuild.result = "SUCCESS"
                    } else {
                        echo "Humans are mortals."
                        currentBuild.result = "FAILURE"
                    }
                }

            }
        }
        /*stage('Cleanup Image') {
            steps {
                script {
                    cleanupCustomImage()
                }
            }
        }*/
    }
    post {
        always {
            script {
                cleanupCustomImage()
                sendEmailNotification()
            }
            cleanWs()
        }
    }
}


def runCustomImage(imageName, args) {
    if ( args.isEmpty() ) {
        args = "--name=jenkins-docker-test -p 49001:8080 -v /var/run/docker.sock:/var/run/docker.sock"
    }

    sh "docker container run -d ${args} ${imageName}"

    // Give container a time for kicking up Jenkins
    sleep(time: 60, unit: 'SECONDS')

    // Get container port
    def containerPort = sh(returnStdout: true,
        script: """
            docker inspect jenkins-docker-test | grep -wE '\"HostPort\": \"[0-9]\\d{0,5}\"' | \
            head -n 1 | sed -e 's/^[[:space:]]*//' | cut -d' ' -f2 | sed -e 's/^\"//' -e 's/\"\$//'
            """
    ).trim()

    // Get Jenkins status code
    def statusCode = sh(returnStdout: true,
        script: '''
            set +x
            curl -s -w "%{http_code}" -o /dev/null http://localhost:${containerPort}
            '''
    ).trim()

    //echo "Get status code ${env.STATUS_CODE} from container jenkins-docker-test"
    return statusCode
}

// Check Jenkins initial admin password
def getInitialAdminPassword(imageName) {
    if ( imageName.isEmpty() ) {
        imageName = "jenkins-docker-test"
    }

    def jenkinsAdminPass = sh(returnStdout: true,
        script: "docker exec -i ${imageName} cat /var/jenkins_home/secrets/initialAdminPassword"
    ).trim()

    return jenkinsAdminPass
}

def cleanupCustomImage() {
    // Just wait for a while
    sleep(time: 10, unit: 'SECONDS')

    //sh 'docker container ps -qf "name=jenkins-docker-test" | xargs -r docker container stop'
    sh 'docker container ls -aqf "name=jenkins-docker-test" | xargs -r docker container rm --force'
    sh 'docker images -q ${env.IMAGE_NAME} | xargs -r docker rmi'
    sh 'docker system prune --force'
}

def sendEmailNotification() {
    script {
        def emailTemplateDir = "/var/jenkins_home/email-templates"
        def emailTemplatePath = "${emailTemplateDir}/jk-email-template.html"
        def rgitUrl = "${env.GIT_URL}"
        def gitUrl = rgitUrl.replace(/.git/, '')
        def gitCommiterEmail = "${env.GIT_COMMITTER_EMAIL}"
        def gitCommitterAvatar = sh(returnStdout: true,
            script:
                """
                echo ${env.GIT_COMMITTER_EMAIL} | md5sum | cut -d' ' -f1
                """
        ).trim()
        def buildStatus = ((currentBuild.currentResult == '' || currentBuild.currentResult == 'SUCCESS') ? 'passed' : (currentBuild.currentResult == 'FAILURE') ? 'failed' : 'warning')
        def cssBgColor = ((currentBuild.currentResult == '' || currentBuild.currentResult == 'SUCCESS') ? '#db4545' : (currentBuild.currentResult == 'FAILURE') ? '#32d282' : '#c6d433')
        
        sh "cp -f ${emailTemplatePath} ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{registryOrg}|${env.REGISTRY_ORG}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{registryRepo}|${env.REGISTRY_REPO}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitUrl}|${gitUrl}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitBranch}|${env.BRANCH_NAME}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitHash}|${env.GIT_COMMIT_HASH}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitMsg}|${env.GIT_COMMIT_MESSAGE}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitterName}|${env.GIT_COMMITTER_NAME}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitterAvatar}|${gitCommitterAvatar}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitUrl}|${env.CHANGE_URL}|g' ${emailTemplateDir}/jk-email.html"
        sh "sed -i 's|{gitCommitterEmail}|${env.CHANGE_AUTHOR_EMAIL}|g' ${emailTemplateDir}/jk-email.html"
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
            body: '${SCRIPT, template="jk-email.html"}'

        // Just wait for email sent
        sleep(time: 10, unit: 'SECONDS')
        //sh "rm -f ${emailTemplateDir}/jk-email.html"
    }
}
