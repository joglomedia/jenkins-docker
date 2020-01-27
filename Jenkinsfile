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
                    if ( env.STATUS_CODE == "200" ) {
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
                sendEmailNotification()
                cleanupBuildImage()
            }
            cleanWs()
        }
    }
}


def testBuildImage() {
    sh "docker container run -d --name=jenkins-docker-test -p 9090:8080 -v /var/run/docker.sock:/var/run/docker.sock ${env.IMAGE_NAME}"
    sleep(time:10,unit:"SECONDS")
    def containerIP = sh(returnStdout: true,
        script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' jenkins-docker-builder"
    ).trim()
    echo "Get jenkins-docker-test conatiner listening on http://${containerIP}:9090"
    env.STATUS_CODE = sh(returnStdout: true,
        script: """
            set +x
            curl -s -w \"%{http_code}\" -o /dev/null http://${containerIP}:9090
            """
    ).trim()
}

def cleanupBuildImage() {
    sh "docker ps -q -f \"name=jenkins-docker-test\" | xargs --no-run-if-empty docker container stop"
    sh "docker container ls -a -q -f \"name=jenkins-docker-test\" | xargs -r docker container rm"
    sh "docker rmi ${env.IMAGE_NAME}"
}

def sendEmailNotification() {
    emailext mimeType: 'text/html',
        subject: "Jenkins build ${currentBuild.currentResult}: ${env.REGISTRY_ORG}/${env.REGISTRY_REPO}#${env.BUILD_NUMBER} (${env.GIT_BRANCH} - ${env.GIT_COMMIT_HASH})",
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
        body: '${SCRIPT, template="jk-email-html.template"}'
}

