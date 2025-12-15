pipeline {
    agent any

    // Variables globales du pipeline
    environment {
        // --- Variables de Configuration ---
	    SONAR_HOST_URL = 'http://10.0.2.15:9000'
        DOCKER_IMAGE = 'malek50/students-app'
        DOCKER_TAG = 'latest'
        NAMESPACE = 'devops'
        
        // Nom du fichier de déploiement dans le dépôt
        DEPLOYMENT_FILE = 'deployment.yaml'

        // Variable gardée pour la cohérence, mais la DB doit être configurée dans deployment.yaml
        SPRING_DATASOURCE_URL = 'jdbc:mysql://mysql-service:3306/db_example?useSSL=false'
    }

    stages {
        // --- ÉTAPE 1 : Préparation & Récupération du Code (GitHub) ---
        stage('1. Checkout Code') {
            steps {
                echo "1. Clonage du code depuis GitHub..."
                git branch: 'master', credentialsId: 'malek-github-pat', url: 'https://github.com/malekbensaid/malek.git'
            }
        }
        
        // --- ÉTAPE 2 : Démarrage de l'Analyse (SonarQube) ---
stage('2. Start SonarQube') {
            steps {
                echo "Démarrage du conteneur SonarQube via Docker..."
                sh 'sudo docker rm -f sonarqube || true' // Ajout de || true pour éviter le crash si non trouvé
                sh 'sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community'

                echo "Attente de la disponibilité de SonarQube (max 120 secondes)..."
                sh '''
                    MAX_ATTEMPTS=120
                    # Correction de l'IP pour utiliser localhost (127.0.0.1) car le port est mappé sur l'hôte
                    SONAR_URL=http://127.0.0.1:9000/api/server/version
                    
                    for i in $(seq 1 $MAX_ATTEMPTS); do
                        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" $SONAR_URL || true)
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "SonarQube est opérationnel (Code HTTP 200 reçu après $i secondes)."
                            exit 0
                        elif [ "$HTTP_CODE" != "000" ] && [ "$HTTP_CODE" != "404" ]; then
                             echo "ATTENTION: Statut inattendu: $HTTP_CODE. Logs SonarQube pour diagnostic:"
                             sudo docker logs sonarqube
                        fi
                        echo "Tentative #$i : Statut actuel: $HTTP_CODE. Attente 1s..."
                        sleep 1
                    done
                    echo "Erreur: SonarQube n'a pas démarré dans les 120 secondes."
                    exit 1
                '''
                echo "Latence de 30 secondes pour la stabilité interne de SonarQube..."
                sh 'sleep 30'
            }
        }
stage('3. SonarQube Analysis') {
            steps {
                echo "3. Exécution de l'analyse SonarQube."

                // Exécute le scan Maven.
                // Le projet Spring Boot est basé sur Maven, donc cette commande est standard.
                sh 'mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=students-app \
                    -Dsonar.host.url=http://127.0.0.1:9000 \
                    -Dsonar.login=admin \
                    -Dsonar.password=admin' // Utiliser le login/mot de passe par défaut pour simplifier (SonarQube 9.9)

                echo "Analyse SonarQube terminée. Voir les résultats sur http://votre-ip-jenkins:9000"
            }
        }
stage('3.5. SonarQube Quality Gate') {
            steps {
                echo "3.5. Attente et vérification du Quality Gate SonarQube..."
                // Utilise le plugin pour bloquer le pipeline jusqu'à ce que le scan soit analysé par SonarQube
                // Et vérifie le résultat du Quality Gate.
                timeout(time: 15, unit: 'MINUTES') {
                    // Note: 'sonar-scanner' est le nom de l'installation SonarQube configurée dans Jenkins.
                    // Si vous n'utilisez pas l'installation globale et préférez une méthode plus simple:
                    // Ajoutez 'withSonarQubeEnv('Your SonarQube Server Name') { ... }'
                    // Sinon, si l'auto-configuration est en place, cela peut suffire.
                    // Si vous ne voulez pas utiliser le plugin, il faut implémenter une boucle de 'curl' comme pour le démarrage.

                    // SOLUTION AVEC LE PLUGIN DE JENKINS (recommandée si installée)
                    // waitForQualityGate abortPipeline: true

                    // Si vous n'utilisez PAS le plugin SonarQube Scanner pour Jenkins, il faut forcer un échec.
                    // On ne peut pas facilement simuler cela avec une simple commande sh ici sans un jeton d'authentification valide.
                    echo "Poursuite du pipeline. Le Quality Gate doit être vérifié manuellement (ou avec un plugin/token)."
                }
            }
        }
        

        // --- ÉTAPE 4 : Création et Envoi de l'Image Docker ---
stage('4. Docker Build and Push') {
            options {
                // Tente de ré-exécuter le stage 3 fois en cas d'échec
                retry(3) 
            }
            steps {
                echo "4. Construction et Push de l'image Docker."
                withCredentials([usernamePassword(credentialsId: 'docker-hub-new-pat', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh "sudo docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    sh "sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "sudo docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
// --- 4.5. NOUVEAU STAGE : Démarrage Minikube ---
stage('4.5. Start Minikube') {
            steps {
                echo "Désactivation temporaire de la protection du noyau pour Minikube..."
                sh 'sudo sysctl fs.protected_regular=0' 

                // Utiliser withEnv pour le MINIKUBE_HOME, c'est très bien.
                withEnv([
                    "MINIKUBE_HOME=${WORKSPACE}/minikube_home",
                    "CHANGE_MINIKUBE_NONE_USER=true" // Ajout de cette variable pour corriger le KUBECONFIG
                ]) {
                    
                    echo "Nettoyage de tout cluster Minikube existant..."
                    // Supprimer le || true si Minikube delete est censé réussir. 
                    sh 'sudo MINIKUBE_HOME="${MINIKUBE_HOME}" minikube delete || true'
                    
                    echo "Démarrage de Minikube (Driver 'none')..."
                    // Minikube peut prendre jusqu'à 300 secondes pour le driver none
                    sh "sudo MINIKUBE_HOME=\"${MINIKUBE_HOME}\" minikube start --driver=none --force --memory=2048mb --wait=300s" 

                    echo "Attribution des permissions au répertoire MINIKUBE_HOME (créé par root) et nettoyage de .kube et .minikube de jenkins..."
                    
                    // Donnez les droits à jenkins sur le dossier de travail.
                    sh 'sudo chown -R $USER:$USER "${MINIKUBE_HOME}"'
                    
                    // Minikube (exécuté avec sudo) a écrit dans /root. Nous devons copier et donner les droits à jenkins.
                    // $HOME est /var/lib/jenkins
                    sh 'sudo cp -R /root/.kube $HOME/ || true'
                    sh 'sudo cp -R /root/.minikube $HOME/ || true'
                    sh 'sudo chown -R $USER:$USER $HOME/.kube $HOME/.minikube'
                    
                    // Mise à jour du contexte pour être sûr que kubectl lise la bonne config.
                    echo "Mise à jour du contexte kubectl..."
                    sh 'minikube update-context'

                    echo "Vérification du statut de Minikube (par l'utilisateur jenkins)..."
                    // Le statut devrait maintenant être "Running" pour Kubeconfig.
                    sh 'minikube status'
                }
            }

        // --- ÉTAPE 5 : Déploiement sur Kubernetes (SIMPLIFIÉ) ---
        stage('5. Deploy to Kubernetes') {
            steps {
                echo "5. Déploiement de l'application sur Minikube (K8S)."
                
                sh """
                    # 1. Assurez-vous que le namespace existe
                    minikube kubectl -- create namespace ${NAMESPACE} --dry-run=client -o yaml | minikube kubectl -- apply -f - || true
                    
                    # 2. Appliquer la configuration K8S (avec le fichier propre)
                    minikube kubectl -- apply -f ${DEPLOYMENT_FILE} -n ${NAMESPACE}
                    
                    # 3. Redémarrer le déploiement pour s'assurer que la dernière image est utilisée
                    minikube kubectl -- rollout restart deployment students-app-deployment -n ${NAMESPACE}
                """
            }
        }
    }
// --- ÉTAPE 6 : Validation de la Connectivité du Déploiement ---
stage('6. Deployment Validation') {
            steps { // <--- Début du bloc steps

                echo "6. Récupération de l'URL et validation de l'accessibilité de l'application."

                // Récupérer l'URL du service Minikube
                script {
                    def appUrl = sh(
                        script: "minikube kubectl -- service students-app-service --url -n ${NAMESPACE}",
                        returnStdout: true
                    ).trim()

                    // Stocker l'URL dans une variable d'environnement pour une utilisation ultérieure
                    env.APP_URL = appUrl
                } // <--- Fin du script {}

                // Les commandes ci-dessous DOIVENT être dans le bloc steps {}

                echo "Application URL: ${env.APP_URL}"

                echo "Vérification de l'accessibilité de l'application (max 60s)..."
                sh '''
                    MAX_ATTEMPTS=60
                    APP_URL_CHECK="${APP_URL}/students" # Exemple d'un endpoint REST qui devrait exister

                    for i in $(seq 1 $MAX_ATTEMPTS); do
                        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" $APP_URL_CHECK || true)

                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "✅ L'application est en ligne ! Réponse HTTP 200 reçue après $i secondes."
                            exit 0
                        fi
                        echo "Tentative #$i : Statut actuel: $HTTP_CODE. Attente 1s..."
                        sleep 1
                    done
                    echo "❌ Échec de la validation: L'application n'a pas répondu avec un code 200 dans les 60 secondes."
                    exit 1
                '''
            } // <--- Fermeture du bloc steps {} à la fin du stage
        }
   
    // --- POST-ACTIONS : Nettoyage ---
    post {
        always {
            echo "Nettoyage : Arrêt et suppression du conteneur SonarQube..."
            sh "sudo docker rm -f sonarqube || true"
            cleanWs()
        }
    }
}