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

        stage('Staging - Tests & Verification') {
            steps {
                echo "🧪 Running tests and validation on staging branch..."
                sh '''
                    # Check required files exist
                    echo "Checking required files..."
                    test -f odoo.Dockerfile || { echo "ERROR: odoo.Dockerfile not found"; exit 1; }
                    test -f config/odoo.conf || { echo "ERROR: odoo.conf not found"; exit 1; }
                    test -d uc16_custom || { echo "ERROR: uc16_custom directory not found"; exit 1; }

                    # Validate odoo.conf syntax (checking for [options] header)
                    echo "Validating odoo.conf..."
                    grep -q "\\[options\\]" config/odoo.conf || { echo "ERROR: Invalid odoo.conf"; exit 1; }

                    echo "✅ All staging validations passed!"
                    echo "📝 Ready for Pull Request to main branch"
                '''
            }
        }

        stage('Production - Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image for PRODUCTION deployment..."
                    echo "Image tag: ${ODOO_IMAGE}"
                    sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."
                }
            }
        }

        stage('Production - Push to Registry') {
            steps {
                script {
                    echo "📤 Pushing image to registry at ${REGISTRY}..."
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
                        sh '''
                            echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin
                            docker push ${ODOO_IMAGE}
                            docker logout ${REGISTRY}
                        '''
                    }
                }
            }
        }

        stage('Production - Deploy to Kubernetes') {
            steps {
                echo "🚀 Deploying to Production Kubernetes cluster..."
                withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
                    script {
                        sh """
                            # Apply the Service
                            echo "Applying Kubernetes service..."
                            kubectl apply -f k8s/odoo-service.yaml --kubeconfig=${KUBECONFIG_FILE}

                            # Apply the Deployment structure
                            echo "Applying Kubernetes deployment..."
                            kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}

                            # Update the image to the new build
                            echo "🔄 Updating deployment image to: ${ODOO_IMAGE}"
                            kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_CONTAINER_NAME}=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}

                            # Wait for rollout to complete
                            echo "⏳ Waiting for rollout to complete..."
                            kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE} --timeout=5m

                            # Verify deployment
                            echo "✅ Verifying deployment..."
                            kubectl get pods -l app=${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}
                        """
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
