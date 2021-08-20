#!/usr/bin/env groovy

/**
 * Jenkins Pipeline
 * References:
 *   - https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *   - https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */

def customImage

pipeline {
    agent any

    environment {
        REGISTRY_ORG = "joglomedia"
        REGISTRY_REPO = "jenkins-docker"
        REGISTRY_URL = "https://registry.hub.docker.com" // https://index.docker.io/v1/
        REGISTRY_CREDENTIAL = "dockerhub_cred"
    }

    stages {
        stage('Initialize') {
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

                    env.IMAGE_NAME = "${env.REGISTRY_ORG}/${env.REGISTRY_REPO}:" + (env.BRANCH_NAME.trim()  == "master") ? "latest" : env.BRANCH_NAME.trim()
                }
                echo "Commit ${env.GIT_COMMIT_HASH} checked out from ${env.BRANCH_NAME} branch."
            }
        }

        stage('Build Image') {
            steps {
                script {
                    // Build Docker image use Dockerfile on the current branch.
                    customImage = docker.build("${env.IMAGE_NAME}")

                    if ( customImage.id != "" ) {
                        echo "Docker image ${customImage.id} built from commit ${env.GIT_COMMIT_HASH}."
                    } else {
                        echo "Failed to build Docker image ${env.IMAGE_NAME}."
                    }
                }
            }
        }

        stage('Test Image') {
            steps {
                script {
                    def statusCode
                    def jenkinsAdminPass

                    customImage.inside {
                        // Wait until Jenkins service is fully up.
                        echo "Waiting for Jenkins to start..."
                        sh "while [[ \$(curl -s -w '%{http_code}' http://127.0.0.1:8080/login?from=%2F -o /dev/null) != '200' ]]; do sleep 5; done"

                        echo "Checking Jenkins image is fully up and running."
                        statusCode = sh(
                            returnStdout: true,
                            script: "curl -s -w '%{http_code}' http://127.0.0.1:8080/login?from=%2F -o /dev/null"
                        ).trim()

                        if ( statusCode == "200" ) {
                            echo "Getting admin pass ${env.JENKINS_PASS} from custom image container."
                            jenkinsAdminPass = sh(
                                returnStdout: true, 
                                script: "cat /var/jenkins_home/secrets/initialAdminPassword"
                            ).trim()
                        } else {
                            echo "Failed to get admin pass ${env.JENKINS_PASS} from custom image container."
                            jenkinsAdminPass = ""
                        }
                    }

                    env.STATUS_CODE = "${statusCode}"
                    env.JENKINS_PASS = "${jenkinsAdminPass}"
                }
            }
        }

        stage('Publish Image') {
            steps {
                script {
                    if ( env.STATUS_CODE == "200" || env.JENKINS_PASS != "" ) {
                        echo "Jenkins-docker is alive and kicking!"

                        // Push image to Docker registry.
                        docker.withRegistry("${env.REGISTRY_URL}", "${env.REGISTRY_CREDENTIAL}") {
                            echo "Pushing custom Docker image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}..."
                            customImage.push("${env.IMAGE_NAME}")
                        }
                        currentBuild.result = "SUCCESS"
                    } else {
                        echo "Humans are mortals."
                        currentBuild.result = "FAILURE"
                    }
                }
            }
        }
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

def cleanupCustomImage() {
    // Try to clean up the custom image.
    sleep(time: 5, unit: 'SECONDS')
    sh 'docker container ps -qf "name=jenkins-docker-test" | xargs -r docker container stop'
    sh 'docker container ls -aqf "name=jenkins-docker-test" | xargs -r docker container rm --force'
    sh 'docker images -q ${env.IMAGE_NAME} | xargs -r docker rmi'
    sh 'docker system prune --force'
}

def sendEmailNotification() {
    def emailTemplateDir = "/var/jenkins_home/email-templates"
    def emailTemplatePath = "${emailTemplateDir}/jenkins-email-template.html"
    def rgitUrl = "${env.GIT_URL}"
    def gitUrl = rgitUrl.replace(/.git/, '')
    def gitCommiterEmail = "${env.GIT_COMMITTER_EMAIL}"
    def gitCommitterAvatar = sh(returnStdout: true,
        script:
        """
        printf \"${env.GIT_COMMITTER_EMAIL}\" | md5sum | cut -d' ' -f1
        """
    ).trim()

    def buildURL = ((env.RUN_DISPLAY_URL) ? "${env.RUN_DISPLAY_URL}" : "${env.BUILD_URL}")

    // Email decoration
    def buildStatus
    def cssColorStatus
    def cssColorRgba

    if (currentBuild.currentResult == '' || currentBuild.currentResult == 'SUCCESS') {
        // success
        buildStatus = "success"
        cssColorStatus = "#32d282"
        cssColorRgba = "50,210,130,0.1"
    } else if (currentBuild.currentResult == 'FAILURE') {
        // failure
        buildStatus = "failure"
        cssColorStatus = "#db4545"
        cssColorRgba = "219,69,69,0.1"
    } else {
        // unknown
        buildStatus = "broken"
        cssColorStatus = "#c6d433"
        cssColorRgba = "198,212,51,0.1"
    }

    // Still looking for better email template method
    sh "cp -f ${emailTemplatePath} ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{registryOrg}|${env.REGISTRY_ORG}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{registryRepo}|${env.REGISTRY_REPO}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitUrl}|${gitUrl}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitBranch}|${env.BRANCH_NAME}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitId}|${env.GIT_COMMIT_HASH}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitMsg}|${env.GIT_COMMIT_MESSAGE}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitterName}|${env.GIT_COMMITTER_NAME}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitterAvatar}|${gitCommitterAvatar}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitUrl}|${env.CHANGE_URL}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{gitCommitterEmail}|${env.CHANGE_AUTHOR_EMAIL}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{jobName}|${env.JOB_NAME}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{buildDuration}|${currentBuild.durationString}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{buildNumber}|${env.BUILD_NUMBER}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{buildUrl}|${buildURL}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{buildStatus}|${buildStatus}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{cssColorStatus}|${cssColorStatus}|g' ${emailTemplateDir}/jenkins-email.html"
    sh "sed -i 's|{cssColorRgba}|${cssColorRgba}|g' ${emailTemplateDir}/jenkins-email.html"

    emailext (
        subject: "Jenkins build ${currentBuild.currentResult}: ${env.REGISTRY_ORG}/${env.REGISTRY_REPO}#${env.BUILD_NUMBER} (${env.GIT_BRANCH} - ${env.GIT_COMMIT_HASH})",
        body: '${SCRIPT, template="jenkins-email.html"}',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        recipientProviders: [[$class: 'CulpritsRecipientProvider'], [$class: 'RequesterRecipientProvider']],
        to: "${env.GIT_COMMITTER_EMAIL}"
    )

    // Just wait for email to sent
    sleep(time: 5, unit: 'SECONDS')
    sh "rm -f ${emailTemplateDir}/jenkins-email.html"
}
