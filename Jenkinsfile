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
    }
    stages {
        stage('Init') {
            steps {
                script {
                    env.GIT_HASH = sh(returnStdout: true,
                        script: "git show --oneline | head -1 | cut -d' ' -f1",
                    ).trim()
                    env.IMAGE_NAME = "${env.IMAGE_REPO}:" + ((env.BRANCH_NAME == "master") ? "latest" : env.GIT_HASH)
                    echo "Commit ${env.GIT_HASH} checked out from ${env.BRANCH_NAME} branch"
                }
            }
        }
        stage('Build Image') {
            steps {
                script {
                    def buildImage = docker.build(env.IMAGE_NAME)
                    if ( buildImage.id != "" ) {
                        echo "Docker image ${buildImage.id} built from commit ${env.GIT_HASH}"
                    } else {
                        echo "Failed building Docker image ${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage('Test Image') {
            steps {
                script {
                    def statusCode = "000"
                    //def buildContainer = buildImage.run("-p 8080 --name=jenkins_docker")
                    //def conport = buildContainer.port()
                    //echo "${buildImage.id} container is running at host:port ${conport}"
                    //env.STATUS_CODE = sh(returnStdout: true,
                    //    script: """
                    //            set +x
                    //            curl -s -w \"%{http_code}\" -o /dev/null http://0.0.0.0:9090
                    //            """
                    //).trim()
                    def container = withDockerContainer(image: "${env.IMAGE_NAME}", args: "-p 9090:8080 --name=jenkins_docker --entrypoint='/usr/local/bin/jenkins.sh'") {
                    //docker.image(env.IMAGE_NAME).withRun("-p 9090:8080 --name=jenkins_docker") { con ->
                        statusCode = sh(returnStdout: true,
                            script: """
                                    set +x
                                    curl -s -w \"%{http_code}\" -o /dev/null http://0.0.0.0:8080
                                    """
                        ).trim()
                    }
                    echo "Get status code ${statusCode} from container ${container.id}"
                }
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( statusCode == "200" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry(env.REGISTRY_URL, env.REGISTRY_CREDENTIAL) {
                            echo "Push image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}"
                            buildImage.push()
                            //if ( env.BRANCH_NAME == "master" ) {
                            //    println "Push image ${env.IMAGE_NAME}:master to registry ${env.REGISTRY_URL}"
                            //    buildImage.push("latest")
                            //} else {
                            //    println "Push image ${env.IMAGE_NAME}:${env.GIT_HASH} to registry ${env.REGISTRY_URL}"
                            //    buildImage.push(env.GIT_HASH)
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
        }
    }
}


def cleanupBuildImage() {
    sh "docker ps -q -f \"name=jenkins_docker\" | xargs --no-run-if-empty docker container stop"
    sh "docker container ls -a -q -f \"name=jenkins_docker\" | xargs -r docker container rm"
    sh "docker rmi ${env.IMAGE_NAME}"
}

