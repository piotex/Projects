multibranchPipelineJob('multibranch-pipeline') {
    displayName('multibranch-pipeline')
    triggers {
        periodicFolderTrigger {
            interval('10m')
        }
    }
    branchSources {
        git {
            id('multibranch-pipeline')
            remote('https://github.com/piotex/Projects.git')
            includes('main')
        }
    }
    factory {
        workflowBranchProjectFactory {
            scriptPath('Python_React_CICD/jenkins/multibranch.Jenkinsfile')
        }
    }
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(7)
        }
    }
}
pipelineJob("deploy") {
    displayName('deploy')
    description("Deploys")
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/piotex/Projects.git')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Python_React_CICD/jenkins/example.Jenkinsfile')
        }
    }
}