## TP Azure + Terraform – Journal de bord

### 1. Contexte et objectif

- **Sujet du TP**: Créer deux VM de développement les plus légères possible sur Azure à l'aide de Terraform, et les placer derrière un **Load Balancer** Azure.
- **Compte Azure**: Abonnement étudiant avec 100$ de crédit.
- **Méthode de connexion**: `az login` avec le CLI Azure.

### 2. Hypothèses et choix techniques

- **Système d'exploitation des VM**: Linux (Ubuntu 22.04 LTS) pour réduire la consommation de ressources et la taille.
- **Taille des VM**: `Standard_B1s` (petite taille, adaptée pour un environnement de dev léger).
- **Accès**:
  - Port **22 (SSH)** ouvert depuis Internet (0.0.0.0/0) pour simplifier le TP.  
  - Authentification **par clé SSH** (fichier `~/.ssh/id_rsa.pub`).
- **Localisation Azure**: `francecentral`.
- **Préfixe des ressources**: `tp-dev-bsi`.

### 3. Recherches effectuées

Indiquer ici, au fur et à mesure, les recherches faites (mots-clés, pages consultées, etc.) :

- [ ] Exemple: "terraform azurerm linux virtual machine" → documentation officielle Terraform `azurerm_linux_virtual_machine`.
- [ ] Exemple: "terraform azure network security group ssh rule" → documentation `azurerm_network_security_group`.
- [ ] Exemple: "ubuntu 22.04 azure image terraform" → recherche de l'`offer` et du `sku` dans la doc Azure.

Tu peux ajouter pour chaque recherche :

- **Date / heure**
- **Mots clés utilisés**
- **Lien de la ressource**
- **Ce que tu en as retenu / appliqué**

### 4. Architecture de la solution

Résumé de ce qui est déployé par Terraform :

- **Resource group**: 1
- **Virtual network**: 1
- **Subnet**: 1
- **Network security group (NSG)**: 1, avec des règles autorisant SSH (port 22) et HTTP (port 80).
- **Public IP (VM)**: 2 (une par VM, pour l'admin SSH).
- **Public IP (Load Balancer)**: 1 (exposition HTTP vers l'extérieur).
- **Network interfaces (NIC)**: 2.
- **Machines virtuelles Linux**: 2, taille `Standard_B1s`.
- **Load Balancer Azure**: 1, de type Public.
- **Backend pool**: 1, contenant les 2 NIC des VMs.
- **Probe**: 1, pour vérifier la dispo des VMs sur le port 80.
- **Load Balancing rule**: 1, qui distribue le trafic HTTP (port 80) vers les VMs.

### 5. Étapes de mise en œuvre

#### 5.1. Pré-requis

- [ ] Installer **Terraform**.
- [ ] Installer le **CLI Azure** (`az`).
- [ ] Vérifier que `~/.ssh/id_rsa.pub` existe ou générer une paire de clés avec:

```bash
ssh-keygen -t rsa -b 4096
```

- [ ] Se connecter à Azure:

```bash
az login
```

#### 5.2. Commandes Terraform

Dans le dossier du projet Terraform:

```bash
terraform init
terraform plan
terraform apply
```

Tu peux noter ici :

- Sorties importantes du `plan` (ressources créées, détruites, modifiées).
- Confirmation de l'exécution de `apply` (date, durée, éventuelles erreurs).

### 6. Tests et validation

- [ ] Récupérer les IP publiques:

```bash
terraform output public_ips
```

- [ ] Tester la connexion SSH à chaque VM:

```bash
ssh azureuser@IP_PUBLIQUE_VM_0
ssh azureuser@IP_PUBLIQUE_VM_1
```

- [ ] Vérifier la version d'Ubuntu, la taille du disque, etc.

Note ici tes observations :

- **VM1**: ...
- **VM2**: ...

### 7. Problèmes rencontrés et solutions

Pour chaque problème, note :

- **Problème**: description
- **Cause (si identifiée)**:
- **Solution appliquée**:
- **Référence** (doc ou page qui t’a aidé):

Exemples de problèmes possibles :

- Erreur d’authentification SSH.
- Problème de version de provider Terraform.
- Conflit de nom de ressource déjà existant dans Azure.

### 8. Améliorations possibles

Idées d'améliorations que tu pourrais mentionner (même si tu ne les implémentes pas) :

- Restreindre l’accès SSH à ton adresse IP publique uniquement.
- Ajouter un script de provisioning (cloud-init) pour installer automatiquement certains outils de dev sur les VM.
- Paramétrer davantage de variables (taille des VM, nombre de VM, etc.).

