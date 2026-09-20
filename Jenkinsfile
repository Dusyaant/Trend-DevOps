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
        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Type aws creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    export AWS_DEFAULT_REGION=us-east-1
                    aws eks update-kubeconfig --region us-east-1 --name trend-eks-cluster
                    kubectl apply -f k8s-deployment.yaml
                    '''
                }
            }
        }
    }
}