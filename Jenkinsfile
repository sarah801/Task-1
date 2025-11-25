pipeline {
  agent any
  
  environment {
    REGISTRY     = "192.168.1.233"
    ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    DOCKER_CREDS = "docker-creds"
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
      
      # Validate odoo.conf syntax
      echo "Validating odoo.conf..."
      grep -q "\[options\]" config/odoo.conf || { echo "ERROR: Invalid odoo.conf"; exit 1; }
      
      echo "✅ Project structure validation passed!"
    '''
      }
    }
    
    stage('Build Docker Image') {
      when {
        // FIX: Changed 'main' to '*main' to match 'main' or 'origin/main'
        branch '*main' 
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
        // FIX: Changed 'main' to '*main'
        branch '*main'
      }
      steps {
        script {
          echo "📤 Pushing image to Local Registry..."
          withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
            sh '''
              echo "$DPASS" | docker login http://${REGISTRY} --username "$DUSER" --password-stdin
              docker push ${ODOO_IMAGE}
              docker logout http://${REGISTRY}
            '''
          }
        }
      }
    }
    
    stage('Deploy to Kubernetes') {
      when {
        // FIX: Changed 'main' to '*main'
        branch '*main'
      }
      steps {
        echo "🚀 Deploying to Kubernetes..."
        withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            # Update deployment with new image
            kubectl apply -f k8s/odoo-deployment.yaml odoo=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}
            kubectl apply -f k8s/odoo-service.yaml odoo=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}
            echo "🔄 Updating deployment image..."
            kubectl set image deployment/uc16-odoo uc16-odoo=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}
            echo "⏳ Waiting for rollout..."
            kubectl rollout status deployment/uc16-odoo --kubeconfig=${KUBECONFIG_FILE}
      '''
          '''
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

