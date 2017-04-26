'use strict'


angular.module('xin.error', [])

  .service "compute_errors", ->
    (error, usager = "", scope_errors = []) ->
      _errors = {}

      if typeof(error) == 'object'
        for key, value of error
          if key in ['nom', 'nom_usage', 'nom_pere', 'nom_mere',
                     'prenom_pere', 'prenom_mere', 'representant_legal_nom', 'representant_legal_prenom']
            if value in ['String value did not match validation regex', 'String value is too long']
              _errors[key] = "Ce champ accepte les lettres, les tirets et les apostrophes. Ces deux caractères spéciaux ne doivent figurer ni en début ni en fin de mot. Ce champ est limité à 30 caractères."
              scope_errors.push("#{usager} #{key} : Ce champ accepte les lettres, les tirets et les apostrophes. Ces deux caractères spéciaux ne doivent figurer ni en début ni en fin de mot. Ce champ est limité à 30 caractères.")
            else
              _errors[key] = value
              scope_errors.push("#{usager} #{key} : #{value}")

          else if key == 'email'
            _errors[key] = "Adresse email invalide"
            scope_errors.push("#{usager} #{key} : Adresse email invalide")

          else if key in ["condition_entree_france", "type_procedure"] and "Not a valid choice." in value
            _errors[key] = "Champ requis."
            scope_errors.push("#{usager} #{key} : Champ requis.")

          else if key == 'telephone'
            if value == 'String value did not match validation regex'
              _errors[key] = 'Le numéro de téléphone doit être composé de chiffres et d\'espace. Il peut commencer par un +'
              scope_errors.push("#{usager} #{key} : Le numéro de téléphone doit être composé de chiffres et d\'espace. Il peut commencer par un +")
            else
              _errors[key] = value
              scope_errors.push("#{usager} #{key} : #{value}")

          else if key == 'prenoms'
            msg = ''
            if typeof(value) == 'object'
              for index, prenom_error of value
                # true_index = parseInt(index) + 1
                tmp_msg = '\n'
                msg += tmp_msg
                if prenom_error in ['String value did not match validation regex', 'String value is too long']
                  tmp_msg = "Ce champ accepte les lettres, les tirets et les apostrophes. Ces deux caractères spéciaux ne doivent figurer ni en début ni en fin de mot. Ce champ est limité à 30 caractères."
                  msg += tmp_msg
                  break
              _errors[key] = msg
              scope_errors.push("#{usager} #{key} : #{msg}")
            else
              _errors[key] = value
              scope_errors.push("#{usager} #{key} : #{value}")

          else if key == 'pays_traverses'
            if typeof(value) == "object"
              msg = ''
              for index, pays_traverses_error of value
                if index == 'pays'
                  msg += "Les pays sont obligatoires.\n"
                else
                  true_index = parseInt(index)+1
                  tmp_msg = "Pays n°#{true_index}: "
                  if typeof(pays_traverses_error) == 'object'
                    for fieldIndex, fieldError of pays_traverses_error
                      tmp_msg += "#{fieldIndex}: #{fieldError}\n"
                  else
                    tmp_msg += "#{pays_traverses_error}\n"
                  msg += tmp_msg
              _errors[key] = msg
              scope_errors.push("#{usager} #{key} : #{msg}")
            else
              _errors[key] = value
              scope_errors.push("#{usager} #{key} : #{value}")

          else if key == "numero_reexamen" and typeof(value) == 'object'
            if value[0] in ["Must be at least 1.", "Not a valid integer."]
              msg = "Le numéro de réexamen doit être supérieur ou égal à 1."
              _errors[key] = msg
              scope_errors.push("#{usager} #{key} : #{msg}")
            else
              _errors[key] = value
              scope_errors.push("#{usager} #{key} : #{value}")
          else
            if value == "Champ requis pour un usager demandeur"
              value = "Champ requis."
            _errors[key] = value
            scope_errors.push("#{usager} #{key} : #{value}")
      else
        _errors['usager_info'] = error
        return _errors

      return _errors
