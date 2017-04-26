Feature: Identification
  En tant qu'utilisateur je veux m'identifier afin d'accéder à la page d'accueil

  Scenario: Connexion normale
    # Je saisis un identifiant et un mot de passe corrects
    Given un utilisateur
    When je m'identifie avec l'identifiant "admin@test.com" et le mot de passe "Azerty&1"
    Then j'accède à la page d'accueil

  # Scenario: Connexion avec un mot de passe incorrect
  #   # Je saisis un identifiant correct et un mot de passe incorrect
  #   Given un utilisateur
  #   When je m'identifie avec l'identifiant "admin@test.com" et le mot de passe "Azerty&2"
  #   Then je suis informé de l'échec de mon identification ("wrong_pwd")
  #
  # Scenario: Connexion avec un mot de passe vide
  #   # Je saisis un identifiant correct et un mot de passe vide
  #   Given un utilisateur
  #   When je m'identifie avec l'identifiant "admin@test.com" et le mot de passe ""
  #   Then je suis informé de l'échec de mon identification ("empty_pwd")
  #
  # Scenario: Connexion avec identifiant incorrect
  #   # Je saisis un identifiant incorrect et un mot de passe correct
  #   Given un utilisateur
  #   When je m'identifie avec l'identifiant "admin2@test.com" et le mot de passe "Azerty&1"
  #   Then je suis informé de l'échec de mon identification ("wrong_email")
  #
  # Scenario: Connexion avec identifiant vide
  #   # Je saisis un identifiant vide et un mot de passe correct
  #   Given un utilisateur
  #   When je m'identifie avec l'identifiant "" et le mot de passe "Azerty&1"
  #   Then je suis informé de l'échec de mon identification ("empty_email")
  #
  # Scenario: Connexion avec identifiant invalide
  #   # Je saisis un identifiant invalide et un mot de passe correct
  #   Given un utilisateur
  #   When je m'identifie avec l'identifiant "admin" et le mot de passe "Azerty&1"
  #   Then je suis informé de l'échec de mon identification ("no_valid_email")
