pipeline {
  agent any

  environment {
    REGISTRY = "192.168.1.233:5000"            // REPLACE with Jenkins VM IP or hostname
    ODOO_IMAGE = "${REGISTRY}/uc16_odoo:latest"
    PG_IMAGE   = "${REGISTRY}/uc16_postgres:latest"
    KUBECONFIG_CRED = "kubeconfig-jenkins"    // Jenkins secret id for kubeconfig
    DOCKER_CREDS = "docker-registry-creds"    // Jenkins creds (optional)
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Images') {
      steps {
        script {
          sh "docker --version || true"
          // Build Odoo
          sh "docker build -t ${ODOO_IMAGE} -f odoo.Dockerfile ."
          // Build Postgres
          sh "docker build -t ${PG_IMAGE} -f postgres.Dockerfile ."
        }
      }
    }

    stage('Push Images') {
      steps {
        script {
          // login if creds exist
          withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DUSER', passwordVariable: 'DPASS')]) {
            sh '''
              if [ -n "$DUSER" ]; then
                echo "$DPASS" | docker login ${REGISTRY} --username "$DUSER" --password-stdin || true
              fi
              docker push ${ODOO_IMAGE}
              docker push ${PG_IMAGE}
            '''
          }
        }
      }
    }

    stage('Deploy to k8s') {
      steps {
        withCredentials([file(credentialsId: "${KUBECONFIG_CRED}", variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=${KUBECONFIG_FILE}
            kubectl apply -f k8s/postgres-deployment.yaml
            kubectl apply -f k8s/postgres-service.yaml
            kubectl apply -f k8s/odoo-deployment.yaml
            kubectl apply -f k8s/odoo-service.yaml
          '''
        }
      }
    }
  }
  stage('Build and Push Docker Image') {
    steps {
        script {
            def imageName = "uc16_odoo"
            def registry = "192.168.1.233:5000"
            sh """
            docker build -t ${registry}/${imageName}:latest -f odoo.Dockerfile .
            docker push ${registry}/${imageName}:latest
            """
        }
    }
  }

  post {
    success { echo "Pipeline completed successfully." }
    failure { echo "Pipeline failed. Check logs." }
  }
}
