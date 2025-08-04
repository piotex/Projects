job('example-99') {
    logRotator(-1, 10)
    steps {
        sh('echo gittt')
    }
}