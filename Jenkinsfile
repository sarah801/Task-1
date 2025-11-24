pipeline {
  agent any

  environment {
    REGISTRY     = "192.168.1.233"
    ODOO_IMAGE   = "${REGISTRY}/uc16_odoo:${BRANCH_NAME}"
    DOCKER_CREDS = "docker-creds"
  }

  stages {

    stage('Checkout') {
      steps {
        echo "Checking out branch: ${env.BRANCH_NAME}"
        checkout scm
      }
    }

    stage('Build Docker Image') {
      when {
        // FIX: Changed 'main' to '*main' to match 'main' or 'origin/main'
        branch '*main' 
      }
      steps {
        script {
          echo "Building Docker image for MAIN branch..."
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
          echo "Pushing image to Local Registry..."
          withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
            sh '''
              echo "$DPASS" | docker login http://${REGISTRY} --username "$DUSER" --password-stdin
              docker push ${ODOO_IMAGE}
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
        echo "Deploying to Kubernetes..."
        withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KUBECONFIG_FILE}
          '''
        }
      }
    }

    stage('Staging Branch Verification') {
      when {
        branch 'stage' // No change needed here
      }
      steps {
        echo "Running staging checks…"
        // You can add linting, unit tests, etc.
      }
    }

  }
 
 // ... post section remains the same



post {

success {

echo "✅ Pipeline executed successfully on ${env.BRANCH_NAME}"

}

failure {

echo "❌ Pipeline failed on ${env.BRANCH_NAME}"

}

}

}
}
