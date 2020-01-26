/*
 * Jenkins Pipeline
 * Ref:
 *  https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry
 *  https://opensourceforu.com/2018/05/integration-of-a-simple-docker-workflow-with-jenkins-pipeline/
 */
pipeline {
    agent any
    //agent { dockerfile true }
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
        stage('Build Docker Image') {
            steps {
                script {
                    image = docker.build("${IMAGE}")
                    println "Newly generated image, " + image.id
                }
            }
        }
        stage('Testing Docker Image') {
            steps {
                script {
                    def container = image.run('-p 9090')
                    def conport = container.port(9090)
                    println image.id + " container is running at host port, " + conport
                    def resp = sh(returnStdout: true,
                                    script: """
                                            set +x
                                            curl -w "%{http_code}" -o /dev/null -s \
                                            http://localhost\":${conport}\"
                                            """
                        ).trim()
                    if ( resp == "200" ) {
                        println "Jenkins-docker is alive and kicking!"
                        docker.withRegistry("${env.REGISTRY}", "${env.REGISTRY_CREDENTIAL}") {
                            if ( "${env.BRANCH_NAME}" == "master" ) {
                                image.push("latest")
                            } else {
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
            cleanWs()
        }
    }
}
