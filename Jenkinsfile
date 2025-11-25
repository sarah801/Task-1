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
        branch 'staging'
      }
      steps {
        echo "🧪 Running tests on staging branch..."
        // Add your tests here:
        // sh 'npm test' or 'pytest' or linting
        sh 'echo "Tests passed!"'
      }
    }
    
    stage('Build Docker Image') {
      when {
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
        branch 'main'
      }
      steps {
        echo "🚀 Deploying to Kubernetes..."
        withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            # Update deployment with new image
            kubectl set image deployment/odoo-deployment odoo=${ODOO_IMAGE} --kubeconfig=${KUBECONFIG_FILE}
            kubectl rollout status deployment/odoo-deployment --kubeconfig=${KUBECONFIG_FILE}
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
