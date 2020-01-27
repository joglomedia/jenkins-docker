/**
 * Jenkins Pipeline
 * Ref:
 *  https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *  https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */

pipeline {
    agent any
    environment {
        IMAGE_REPO = "eslabsid/jenkins-docker"
        REGISTRY_URL = "https://registry.hub.docker.com/"
        REGISTRY_CREDENTIAL = "dockerhub-cred"
        GIT_COMMIT_HASH = ""
        GIT_COMMIT_MESSAGE = ""
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
                    env.IMAGE_NAME = "${env.IMAGE_REPO}:" + ((env.BRANCH_NAME == "master") ? "latest" : env.GIT_COMMIT_HASH)
                    echo "Commit ${env.GIT_COMMIT_HASH} checked out from ${env.BRANCH_NAME} branch"
                }
            }
        }
        stage('Build Image') {
            steps {
                script {
                    def buildImage = docker.build(env.IMAGE_NAME)
                    if ( buildImage.id != "" ) {
                        echo "Docker image ${buildImage.id} built from commit ${env.GIT_COMMIT_HASH}"
                    } else {
                        echo "Failed building Docker image ${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage('Test Image') {
            steps {
                script {
                    /*def container = buildImage.run("-p 9090:8080 --name=jenkins_docker")
                    def conport = container.port()
                    echo "${buildImage.id} container is running at host:port ${conport}"
                    env.STATUS_CODE = sh(returnStdout: true,
                        script: """
                                set +x
                                curl -s -w \"%{http_code}\" -o /dev/null http://0.0.0.0:9090
                                """
                    ).trim()
                    */
                    def container = withDockerContainer(image: "${env.IMAGE_NAME}", args: "-p 9090:8080 --name=jenkins_docker --entrypoint=''") {
                        sleep(time:10,unit:"SECONDS")
                        env.STATUS_CODE = sh(returnStdout: true,
                            script: """
                                    set +x
                                    curl -s -w \"%{http_code}\" -o /dev/null http://0.0.0.0:9090
                                    """
                        ).trim()
                    }
                    echo "Get status code ${env.STATUS_CODE} from container ${container.id}"
                }
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( env.STATUS_CODE != "000" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry(env.REGISTRY_URL, env.REGISTRY_CREDENTIAL) {
                            echo "Push image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}"
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
                        echo "Humans are mortals."
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
            }
            cleanWs()
            sendEmailNotification()
        }
    }
}


def cleanupBuildImage() {
    sh "docker ps -q -f \"name=jenkins_docker\" | xargs --no-run-if-empty docker container stop"
    sh "docker container ls -a -q -f \"name=jenkins_docker\" | xargs -r docker container rm"
    //sh "docker rmi ${env.IMAGE_NAME}"
}

def sendEmailNotification() {
    emailext mimeType: 'text/html',
        subject: "Jenkins build ${currentBuild.currentResult}: ${env.JOB_NAME}#${env.BUILD_NUMBER} (${GIT_BRANCH} - ${GIT_COMMIT_HASH}",
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
        body: $PROJECT_DEFAULT_CONTENT
}

