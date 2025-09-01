pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/piotex/Projects.git'
        NEXUS_REPO = 'maven-snapshots'
        GROUP_ID = "com/python_react_cicd"
        ARTIFACT_ID = "backend"
        VERSION = "1.0.0-SNAPSHOT"
        TIMESTAMP = sh(script: 'date +%Y%m%d%H%M%S', returnStdout: true).trim()
    }

    stages {
        stage('Checkout Code') {
            steps {
                cleanWs()
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh 'python3 -m venv .venv'
                    sh '.venv/bin/pip install -r requirements.txt'
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh '.venv/bin/pytest'
                }
            }
        }

        stage('Build and Push to Nexus') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh "zip -r ${TIMESTAMP}.zip . -x \"*.venv*\" -x \"*.pytest_cache*\" -x \"*__pycache__*\""
                    
                    withCredentials([usernamePassword(credentialsId: "nexus-credentials", passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USER')]) {
                        sh '''
                            curl -v \
                            --user "${NEXUS_USER}:${NEXUS_PASSWORD}" \
                            --upload-file "${TIMESTAMP}.zip" \
                            "http://192.168.56.110:9050/repository/${NEXUS_REPO}/${GROUP_ID}/${ARTIFACT_ID}/${VERSION}/${TIMESTAMP}.zip"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
