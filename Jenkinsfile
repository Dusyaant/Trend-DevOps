pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "prospendeo/trend-app"
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${env.BUILD_ID} -t ${DOCKER_IMAGE}:latest ."
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${env.BUILD_ID}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
        stage('Clean Up Local Images') {
            steps {
                sh "docker rmi ${DOCKER_IMAGE}:${env.BUILD_ID} ${DOCKER_IMAGE}:latest"
            }
        }
    }
}