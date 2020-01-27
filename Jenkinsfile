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
                    def image = docker.build(env.IMAGE_NAME)
                    if ( image.id != "" ) {
                        echo "Docker image ${image.id} built from commit ${env.GIT_HASH}"
                    } else {
                        echo "Failed building Docker image ${env.IMAGE_NAME}"
                    }
                }
            }
        }
        stage('Test Image') {
            steps {
                script {
                    //def container = image.run("-p 8080 --name=jenkins_docker")
                    //def conport = container.port(8080)
                    //println image.id + " container is running at host:port " + conport
                    //env.STATUS_CODE = sh(returnStdout: true,
                    //    script: '''
                    //            set +x
                    //            curl -w "%{http_code}" -o /dev/null -s http://\"${contport}\"
                    //            '''
                    //).trim()
                    //docker.withDockerContainer(env.IMAGE_NAME) {
                    docker.image(env.IMAGE_NAME).inside("-p 9090:8080") {
                        env.STATUS_CODE = sh(returnStdout: true,
                            script: """
                                    set +x
                                    curl -w \"%{http_code}\" -o /dev/null -s http://0.0.0.0:8080
                                    """
                        ).trim()
                    }
                }
            }
        }
        stage('Register Image') {
            steps {
                script {
                    if ( env.STATUS_CODE == "200" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry(env.REGISTRY_URL, env.REGISTRY_CREDENTIAL) {
                            echo "Push image ${env.IMAGE_NAME} to registry ${env.REGISTRY_URL}"
                            image.push()
                            //if ( env.BRANCH_NAME == "master" ) {
                            //    println "Push image ${env.IMAGE_NAME}:master to registry ${env.REGISTRY_URL}"
                            //    image.push("latest")
                            //} else {
                            //    println "Push image ${env.IMAGE_NAME}:${env.GIT_HASH} to registry ${env.REGISTRY_URL}"
                            //    image.push(env.GIT_HASH)
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
        stage('Clean up Image') {
            steps {
                script {
                    sh "docker ps -q -f \"name=jenkins_docker\" | xargs --no-run-if-empty docker container stop"
                    sh "docker container ls -a -q -f \"name=jenkins_docker\" | xargs -r docker container rm"
                    sh "docker rmi ${env.IMAGE_NAME}"
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
