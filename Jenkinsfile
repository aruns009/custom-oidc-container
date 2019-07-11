#!/usr/bin/env groovy
def projectName = 'nginx-oidc'
def label = "${projectName}-worker-${UUID.randomUUID().toString()}"

podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app.kubernetes.io/name: ${label}
spec:
  containers:
  - name: docker-compose
    image: kubernetes.docker.engineering.csu.local:12345/docker/compose:1.23.2
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 500m
        memory: 256Mi
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
) {

  node(label) {

    def checkoutSCM = checkout scm
    notifyBitbucket()

    try {

      def gitBranch = checkoutSCM.GIT_LOCAL_BRANCH
      echo "branch = '${gitBranch}'"

      def gitCommit = checkoutSCM.GIT_COMMIT
      def shortGitCommit = "${gitCommit[0..10]}"
      echo "commit = '${shortGitCommit}'"

      stage('build') {
        container('docker-compose') {
          if (gitBranch == 'master') {
            sh 'docker-compose build'
          } else {
            sh "VERSION=${shortGitCommit} docker-compose build"
          }
        }
      }

      stage('push') {
        container('docker-compose') {
          withCredentials([[
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'mssjenkins',
            usernameVariable: 'USERNAME',
            passwordVariable: 'PASSWORD'
          ]]) {
            sh "docker login -u ${env.USERNAME} -p ${env.PASSWORD} lego.docker.engineering.csu.local:12345"
          }
          if (gitBranch == 'master') {
            sh 'docker-compose push'
          } else {
            sh "VERSION=${shortGitCommit} docker-compose push"
          }
        }
      }
      currentBuild.result = 'SUCCESS'
    } catch(err) {
      currentBuild.result = 'FAILED'
    }
    notifyBitbucket()
  }
}
