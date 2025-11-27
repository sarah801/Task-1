pipeline {
    agent any
    environment {
        REGISTRY     = "192.168.1.233"
        ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        DOCKER_CREDS = "docker-creds"
        K8S_CONTAINER_NAME = "odoo"
        K8S_DEPLOYMENT_NAME = "uc16-odoo"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "Checking out branch: ${env.BRANCH_NAME}"
                checkout scm
            }
        }
        stage('Fetch last code updates') {
            steps {
                git(url: 'https://github.com/sarah801/Task-1.git', branch: 'stage')
                sh '''
                    echo "📥 Fetching latest code from stage branch..."
                    ls -la
                    git log --oneline -5
                    echo "✅ Code fetched successfully!"
                '''
            }
        }
        stage('Build Image') {
            steps {
                sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
                    echo "Image tag: ${ODOO_IMAGE}"
                    sh "docker push public.ecr.aws/k9h2m6v6/radioshash-repo:${env.BUILD_NUMBER}"
                    sh '''
                        echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin
                        docker push ${ODOO_IMAGE}
                        docker logout ${REGISTRY}
                    '''
                }
            }
        }
        stage('Update k8s files') {
            steps {
                sh "sed -i 's|image:.*|image: ${ODOO_IMAGE}|' ./k8s/odoo-deployment.yml"
            }
        }
        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
                    script {
                        echo "Applying Kubernetes service..."
                        sh "kubectl apply -f k8s/odoo-service.yaml --kubeconfig=${KUBECONFIG_FILE}"
                        echo "Applying Kubernetes deployment..."
                        sh "kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}"
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                if (env.BRANCH_NAME == 'stage') {
                    echo "✅ Staging validation successful! Ready to create PR to main branch."
                } else if (env.BRANCH_NAME == 'main') {
                    echo "✅ Production deployment successful!"
                    echo "📦 Deployed image: ${ODOO_IMAGE}"
                }
            }
        }
        failure {
            script {
                if (env.BRANCH_NAME == 'stage') {
                    echo "❌ Staging validation failed! Fix issues before creating PR."
                } else if (env.BRANCH_NAME == 'main') {
                    echo "❌ Production deployment failed!"
                }
            }
        }
        always {
            echo "Pipeline completed for branch: ${env.BRANCH_NAME}"
        }
    }
} 
