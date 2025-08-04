

// pipelineJob('deploy') {
//     definition {
//         cpsScm {
//             scm {
//                 git {
//                     remote {
//                         url('https://github.com/jenkinsci/job-dsl-plugin.git')
//                     }
//                     branch('main') 
//                 }
//             }
//             scriptPath('Python_React_CICD/jenkins/seedjob.groovy') 
//         }
//     }
// }

// multibranchPipelineJob('multibranch-cicd') {
//     branchSources {
//         git {
//             id('multibranch-cicd') 
//             remote('https://github.com/jenkinsci/job-dsl-plugin.git')
//         }
//     }
//     orphanedItemStrategy {
//         discardOldItems {
//             numToKeep(20)
//         }
//     }
// }