Feature: Utilitario - Enviar un evento válido al Barista Bot

  # NO es un caso de prueba: vive fuera de la carpeta features/ para que el Runner no lo ejecute solo.
  # Se invoca desde barista_bot.feature con:
  #   * call read('classpath:helpers/barista-evento.feature') { evento: 'Iniciar Pedido' }
  # Sirve para llevar la máquina de estados hasta el estado inicial que necesita cada escenario.
  # Solo se usa con eventos que DEBEN ser válidos: si la transición no es válida, falla la preparación.

  Scenario: Enviar evento de preparación
    Given url baseUrl
    And path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: '#(evento)' }
    When method post
    Then status 200
    And match response.valida == true
