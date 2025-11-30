pipeline {
    agent any

    environment {
        REGISTRY     = "192.168.1.233"
        ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        DOCKER_CREDS = "docker-creds"
        K8S_CONTAINER_NAME = "odoo"
        K8S_DEPLOYMENT_NAME = "uc16-odoo"
    }

    stage{
 stage('Fitch last code updates'){
     steps{
       git(url: 'https://github.com/sarah801/Task-1', branch: 'stage')
       sh "ls -la"
     }
        }

        stage('build Image'){
     steps{
       echo "🐳 Building Docker image for PRODUCTION deployment..."
       sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."                   
       withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
                    echo "Image tag: ${ODOO_IMAGE}"
                    sh '''
                            echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin
                            docker push ${ODOO_IMAGE}
                            docker logout ${REGISTRY}
                        '''
                }
     }
   }
     stage('update k8s files'){
     steps{
       sh "sed -i 's|image:.*|image: ${ODOO_IMAGE}|g\' K8s/odoo-deployment.yaml"
     }
   }

   stage('Deploy'){
     steps{
        withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
               script{
                     sh "kubectl apply -f k8s/odoo-service.yaml --kubeconfig=${KUBECONFIG_FILE}"
                     sh "kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}"
                    echo "⏳ Waiting for rollout to complete..."
                    sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}"   
                    echo "✅ Verifying deployment..."
                    sh "kubectl get pods -l app=${K8S_DEPLOYMENT_NAME} --kubeconfig=${KUBECONFIG_FILE}"
            }
        }
     }
   }

