jobDsl {
    script '''
        pipelineJob('my-new-pipeline') {
            definition {
                cps {
                    script('node { echo "Hello from new pipeline" }')
                }
            }
        }
    '''
}