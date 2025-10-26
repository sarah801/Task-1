pipeline {
  agent any

  environment {
    REGISTRY        = "192.168.1.233:5000"       // Local registry IP
    ODOO_IMAGE      = "${REGISTRY}/uc16_odoo:latest"
    KUBECONFIG_CRED = "kubeconfig-jenkins"       // Secret file credential ID
    DOCKER_CREDS    = "docker-registry-creds"    // Username/password credential ID
  }

  stages {

 stage('Checkout') {
      steps {
        echo "Checking out source code..."
        checkout scmGit(branches: [[name: 'main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github_credentials', url: 'https://github.com/sarah801/Task-1.git']])
      }
    }


    stage('Build Docker Images') {
      steps {
        script {
          echo "Building Odoo  image..."
          sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."
          
        }
      }
    }

    stage('Push Docker Images') {
      steps {
        script {
          echo "Pushing images to local registry..."
          withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
            sh '''
              if [ -n "$DUSER" ]; then
                echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin || true
              fi
              docker push ${ODOO_IMAGE}
              
            '''
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        echo "Deploying to Kubernetes..."
        withCredentials([file(credentialsId: "${KUBECONFIG_CRED}", variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=${KUBECONFIG_FILE}
            kubectl apply -f k8s/odoo-deployment.yaml
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completed successfully."
    }
    failure {
      echo "❌ Pipeline failed. Check the logs in Jenkins."
    }
  }
}
