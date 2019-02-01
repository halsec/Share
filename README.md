# Share
Remediation FS
Etapes 	Actions	Nom du rapport Varonis / Planification	Scripts PS et description 
XM001WAI\F$\Scripts\Share
1.		Répertoires Racines	MPX - Dossiers Racines Permissions
A planifier toutes les semaines	\RepertoiresRacines\TraitementRepertoiresRacinesv2.ps1
Ajoute Everyone avec Delete en Deny pour les dossiers sous Partages, Share_Smbdonnees et SHARE
2.		Dossiers/fichiers sans Administrateurs	MPX - Folders with No Admin	\RepertoiresSansAdmins\ TraitementRepertoiresPropriétairesv3.ps1
3.		Héritages cassés	MPX_HM003W33_HeritagePB
MPX_Entrepots_HeritagePB
MPX_MonShowRoom_HeritagePB	\Heritage\Heritage_TraitementRepertoiresRacinesv1.ps1
4.		Permissions avec groupes désactivés	Permissions Comptes Desactives_HM003W33
Permissions Comptes Desactives_Entrepots
Permissions Comptes Desactives_MonShowRoom	\DisabledAccounts\Partages_permissions_DisabledAccountsv1.ps1 avec comme fichier source un csv Varonis ; exemple : HM003W33_PermissionsAvecComptesDesactives.csv
5.		Permissions avec SID inconnus	MPX_Permissions - SID non resolu_HM003W33
MPX_Permissions - SID non resolu_MonShowRoom
MPX_Permissions - SID non resolu_Entrepots	\SIDInconnus\Partages_permissions_SIDInconnus.ps1 avec comme fichier source un csv Varonis ; exemple : Permissions - SID non resolu_HM003W33test.csv
6.		Groupes d’accès globaux	MPX - Open Files Permissions	TBD
7.		Etat des lieux, rapports de suivi	Monoprix-FileServersStatistics
MPX-HM003W33-StatsSuivi	Ce tableau nous permet de suivre les opérations de remédiation. Par colonnes : Nombre de fichiers/dossiers, Nombre de dossiers « ouverts », Nombre de dossiers avec des problèmes d’héritage, Nombre de dossiers avec des permissions contenant des SID inconnus, Nombre de dossiers avec des permissions contenant des utilisateurs (ACE)
8.		Propriétaire par dossiers racine	MPX_HM003W33 Ownership - File Server	Les propriétaires doivent être identifiés lorsque des données sont déplacées, archivées ou lorsque les autorisations d'accès doivent être modifiées.
9.		Propriétaire par sous dossiers		
10.		Données périmées	04-f-02. Stale Data avec un seuil à définit. Exemple 01/01/2007	Liste les dossiers contenant des fichiers qui n’ont pas été modifiées après une date limite.
