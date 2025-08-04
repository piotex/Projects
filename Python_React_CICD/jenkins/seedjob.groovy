pipelineJob('my-github-pipeline') {
    definition {
        scm {
            git {
                remote {
                    url('https://github.com/piotex/Projects.git')
                }
                branch('main')
            }
        }
        scriptPath('Python_React_CICD/jenkins/example.Jenkinsfile')
    }
}