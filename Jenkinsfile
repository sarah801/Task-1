pipeline {
    agent any

    environment {
        // Ensure your Jenkins server can reach this IP (and allow HTTP if not HTTPS)
        REGISTRY     = "192.168.1.233" 
        ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        DOCKER_CREDS = "docker-creds"
        // It is good practice to define the container name used in K8s deployment here
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

        stage('Staging - Tests & Verification') {
            when {
                branch 'stage'
            }
            steps {
                echo "🧪 Validating project structure on stage branch..."
                sh '''
                    # Check required files exist
                    echo "Checking required files..."
                    test -f odoo.Dockerfile || { echo "ERROR: odoo.Dockerfile not found"; exit 1; }
                    test -f config/odoo.conf || { echo "ERROR: odoo.conf not found"; exit 1; }
                    test -d uc16_custom || { echo "ERROR: uc16_custom directory not found"; exit 1; }

                    # Validate odoo.conf syntax (checking for [options] header)
                    echo "Validating odoo.conf..."
                    grep -q "\\[options\\]" config/odoo.conf || { echo "ERROR: Invalid odoo.conf"; exit 1; }
                    
                    echo "✅ Project structure validation passed!"
                '''
            }
        }

        stage('Build Docker Image') {
            when {
                // In Multibranch pipelines, strictly matching 'main' is usually safest
                branch 'main' 
            }
            steps {
                script {
                    echo "🐳 Building Docker image for MAIN branch..."
                    sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."
                }
            }
        }

        stage('Push Docker Image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "📤 Pushing image to Local Registry..."
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
                        // Added handling for insecure-registry if your IP uses HTTP
                        sh '''
                            echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin
                            docker push ${ODOO_IMAGE}
                            docker logout ${REGISTRY}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo "🚀 Deploying to Kubernetes..."
                withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
                    script {
                        sh """
                            # 1. Apply the Service (usually static)
                            kubectl apply -f k8s/odoo-service.yaml --kubeconfig=${KUBECONFIG_FILE}
                            
                            # 2. Apply the Deployment structure (ensures object exists)
                            kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}
                            
                            # 3. Force update the image to the specific build tag
                            echo "🔄 Updating deployment image to: ${ODOO_IMAGE}"
                            kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_CONTAINER_NAME}=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}
                            
                            # 4. Wait for rollout
                            echo "⏳ Waiting for rollout..."
                            kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline executed successfully on ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Pipeline failed on ${env.BRANCH_NAME}"
        }
    }
}
