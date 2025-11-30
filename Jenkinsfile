pipeline {
    agent any

    environment {
        REGISTRY     = "192.168.1.233"
        ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${BRANCH_NAME}-${BUILD_NUMBER}"
        DOCKER_CREDS = "docker-creds"
        K8S_CONTAINER_NAME = "odoo"
        K8S_DEPLOYMENT_NAME = "uc16-odoo"
    }

    stages {
        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
                    script {

                        echo "🚀 Applying Service & Deployment..."
                        sh "kubectl apply -f k8s/odoo-service.yaml --kubeconfig=${KUBECONFIG_FILE}"
                        sh "kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}"

                        echo "⏳ Waiting for rollout to complete..."
                        sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}"

                        echo "✅ Deployment Verified. Listing pods..."
                        sh "kubectl get pods -l app=${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}"
                    }
                }
            }
        }
    }
}
