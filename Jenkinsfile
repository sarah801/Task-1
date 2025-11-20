pipeline {
  agent any

  environment {
    REGISTRY        = "192.168.1.233"       // Local registry IP
    ODOO_IMAGE      = "${REGISTRY}/uc16_odoo:latest"
    DOCKER_CREDS    = "docker-creds"    // Username/password credential ID
  }

  stages {

 stage('Checkout') {
      steps {
        echo "Checking out source code..."
        checkout scmGit(branches: [[name: 'main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github_conf', url: 'https://github.com/sarah801/Task-1.git']])
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
                echo "$DPASS" | docker login http://${REGISTRY} --username "$DUSER" --password-stdin || true
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
        withCredentials([file(credentialsId: 'kubeconfigCred', variable: 'KubeConfigCred')]) {
          sh '''
            
            kubectl apply -f k8s/odoo-deployment.yaml --kubeconfig=${KubeConfigCred}
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
