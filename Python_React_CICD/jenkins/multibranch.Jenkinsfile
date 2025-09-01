pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/piotex/Projects.git'
        NEXUS_HOST = '192.168.56.110:9050'
        NEXUS_CREDENTIALS = 'nexus-credentials' 
        NEXUS_REPO = 'maven-snapshots'
        // NEXUS_REPO = 'maven-releases'
        GROUP_ID = 'com/python_react_cicd'
        ARTIFACT_ID = 'backend'
        
        FULL_VERSION = "1.0.0" 
        TIMESTAMP = sh(script: 'date +%Y%m%d%H%M%S', returnStdout: true).trim()
        UNIQUE_VERSION = "${TIMESTAMP}-SNAPSHOT"
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
                    sh "zip -r ${env.UNIQUE_VERSION}.zip . -x \"*.venv*\" -x \"*.pytest_cache*\" -x \"*__pycache__*\""
                    
                    withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIALS}", passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USER')]) {
                        echo "Przesyłanie artefaktu do Nexus..."
                        sh '''
                            curl -v \\
                            --user "${NEXUS_USER}:${NEXUS_PASSWORD}" \\
                            --upload-file "${UNIQUE_VERSION}.zip" \\
                            "http://${NEXUS_HOST}/repository/${NEXUS_REPO}/${GROUP_ID}/${ARTIFACT_ID}/${FULL_VERSION}/${UNIQUE_VERSION}.zip"
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