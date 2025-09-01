pipeline {
    agent any

    environment {
        REPO_URL = 'https://github.com/piotex/Projects.git'
        NEXUS_HOST = '192.168.56.110:9050'
        NEXUS_CREDENTIALS = 'nexus-credentials' 
        NEXUS_REPO = 'maven-releases'
        GROUP_ID = 'com/python_react_cicd'

        ARTIFACT_ID = 'backend'
        VERSION = '1.0.0'
        ARTIFACT_FILE = "${ARTIFACT_ID}-${VERSION}.zip"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Sprawdzanie kodu z repozytorium Git...'
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh '''
                        python -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh '. venv/bin/activate'
                    sh 'pytest'
                }
            }
        }

        stage('Build and Push to Nexus') {
            steps {
                dir('Python_React_CICD/backend') {
                    sh "zip -r ${ARTIFACT_FILE} ."
                    withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIALS}", passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USER')]) {
                        sh "curl -v --user \"${NEXUS_USER}:${NEXUS_PASSWORD}\" --upload-file ${ARTIFACT_FILE} http://${NEXUS_HOST}/repository/${NEXUS_REPO}/${GROUP_ID}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_FILE}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline zakończony.'
        }
        success {
            echo 'Pipeline zakończył się sukcesem!'
        }
        failure {
            echo 'Pipeline zakończył się błędem!'
        }
    }
}