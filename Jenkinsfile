/*
 * Jenkins Pipeline
 * Ref:
 *  https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *  https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */
pipeline {
    agent any
    environment {
        IMAGE = "eslabsid/jenkins-docker"
        REGISTRY = "https://registry.hub.docker.com/"
        REGISTRY_CREDENTIAL = 'dockerhub-cred'
    }
    stages {
        stage('Verify Git Repo') {
            steps {
                script {
                    env.GIT_HASH = sh(
                        script: "git show --oneline | head -1 | cut -d' ' -f1",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        stage('Spin Up Builder') {
            steps {
                script {
                    def image = docker.build("${IMAGE}")
                    if ( image.id != "" ) {
                        println "Newly built Docker image : " + image.id
                    } else {
                        println "Failed building Docker image"
                    }
                }
            }
        }
        stage('Test Builder') {
            steps {
                script {
                    def builder_container = image.run("-d -p 9090:8080 --name=jenkins_docker")
                    def conport = builder_container.port(9090)
                    println image.id + " container is running at host:port " + conport
                    env.STATUS_CODE = sh(
                        script: curl -w "%{http_code}" -o /dev/null -s http://${conport},
                        returnStdout: true
                    ).trim()
                    if ( "${env.STATUS_CODE}" == "200" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry("${env.REGISTRY}", "${env.REGISTRY_CREDENTIAL}") {
                            if ( "${env.BRANCH_NAME}" == "master" ) {
                                println "Push image ${env.IMAGE}:master to registry ${env.REGISTRY}"
                                image.push("latest")
                            } else {
                                println "Push image ${env.IMAGE}:${env.GIT_HASH} to registry ${env.REGISTRY}"
                                image.push("${env.GIT_HASH}")
                            }
                        }
                        currentBuild.result = "SUCCESS"
                    } else {
                        println "Humans are mortals."
                        currentBuild.result = "FAILURE"
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                sh "docker ps -q -f \"name=jenkins_docker\" | xargs --no-run-if-empty docker container stop"
                sh "docker container ls -a -q -f \"name=jenkins_docker\" | xargs -r docker container rm"
                sh "docker rmi ${env.IMAGE}"
            }
            cleanWs()
        }
    }
}
