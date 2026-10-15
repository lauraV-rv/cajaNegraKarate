@api @barista_bot @transicion_estados
Feature: Robot Cafetero Automatizado (Barista Bot) - Transición de estados
  Como operador del robot cafetero
  Quiero que el robot respete la máquina de estados del pedido
  Para garantizar que solo se ejecuten transiciones válidas y se rechacen las inválidas

  # Estados: En Espera -> Moliendo -> Calentando Agua -> Sirviendo -> En Espera (+ Error de Insumos)
  # Eventos API: Iniciar Pedido | Terminar Molienda | Alcanzar Temperatura | Terminar Llenado
  #              Sin Ingredientes | Recargar y Reiniciar
  #
  # Contrato de las APIs de máquina de estados del taller (el mismo del Torniquete):
  #   GET  barista-bot/estado    -> { estadoActual, historial, maquina }
  #   POST barista-bot/evento    -> { estadoAnterior, evento, estadoNuevo, valida, accion }
  #   POST barista-bot/reiniciar -> { estadoActual }
  #   Una transición INVÁLIDA responde HTTP 200 con valida=false y el estado NO cambia.
  # Los nombres de estado se comparan con regex (#regex .*Nombre.*) para tolerar prefijos como "S2 (Moliendo)".

  Background:
    * url baseUrl
    # Reinicio obligatorio: cada escenario (y cada fila de Examples) parte de "En Espera"
    Given path 'barista-bot/reiniciar'
    And header Accept = 'application/json'
    When method post
    Then status 200
    # Se verifica la precondición de partida
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*En Espera.*'
    # Lleva el robot hasta el estado inicial de cada caso enviando una lista de eventos separados por coma
    * def prepararEstado =
      """
      function(pasos) {
        if (pasos == 'ninguno') return;
        var eventos = pasos.split(',');
        for (var i = 0; i < eventos.length; i++) {
          karate.call('classpath:helpers/barista-evento.feature', { evento: eventos[i].trim() });
        }
      }
      """

  # ---------------------------------------------------------------------------
  # TRANSICIONES VÁLIDAS
  # ---------------------------------------------------------------------------

  @Issue-1 @smoketest @req_iniciar_pedido
  Scenario: Cliente inicia un pedido válido y el robot pasa de En Espera a Moliendo
    # Dado que el sistema está en el estado En Espera
    # Y el cliente selecciona una bebida y realiza el pago
    # Cuando el sistema procesa el evento Iniciar Pedido
    # Entonces el estado cambia a Moliendo
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Iniciar Pedido' }
    When method post
    Then status 200
    And match response.valida == true
    And match response.estadoAnterior == '#regex .*En Espera.*'
    And match response.estadoNuevo == '#regex .*Moliendo.*'
    # Verifica que el estado quedó persistido
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*Moliendo.*'

  @Issue-2 @req_flujo_completo_pedido
  Scenario: Flujo completo de preparación hasta volver a En Espera
    # Dado que el sistema está en el estado Moliendo (tras iniciar un pedido)
    * call read('classpath:helpers/barista-evento.feature') { evento: 'Iniciar Pedido' }

    # Cuando finaliza la molienda -> Entonces el estado cambia a Calentando Agua
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Terminar Molienda' }
    When method post
    Then status 200
    And match response.valida == true
    And match response.estadoNuevo == '#regex .*Calentando Agua.*'

    # Cuando el agua alcanza la temperatura óptima -> Entonces el estado cambia a Sirviendo
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Alcanzar Temperatura' }
    When method post
    Then status 200
    And match response.valida == true
    And match response.estadoNuevo == '#regex .*Sirviendo.*'

    # Cuando se completa el llenado del vaso -> Entonces el estado retorna a En Espera
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Terminar Llenado' }
    When method post
    Then status 200
    And match response.valida == true
    And match response.estadoNuevo == '#regex .*En Espera.*'

    # El robot queda listo para un nuevo pedido
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*En Espera.*'

  @Issue-3 @req_sin_ingredientes
  Scenario Outline: Escasez de insumos durante <estado_actual> lleva al robot a Error de Insumos
    # Dado que el sistema está en el estado <estado_actual>
    # Y el sensor detecta escasez de café o leche
    # Cuando el sistema procesa el evento Sin Ingredientes
    # Entonces el sistema interrumpe el flujo y el estado cambia a Error de Insumos
    * eval prepararEstado('<pasos_previos>')
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*<estado_actual>.*'
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Sin Ingredientes' }
    When method post
    Then status 200
    And match response.valida == true
    And match response.estadoNuevo == '#regex .*Error de Insumos.*'

    Examples:
      | estado_actual   | pasos_previos                                         |
      | Moliendo        | Iniciar Pedido                                        |
      | Calentando Agua | Iniciar Pedido,Terminar Molienda                      |
      | Sirviendo       | Iniciar Pedido,Terminar Molienda,Alcanzar Temperatura |

  @Issue-4 @req_recarga_reinicio
  Scenario: El técnico recarga insumos y el robot vuelve de Error de Insumos a En Espera
    # Dado que el sistema está en el estado Error de Insumos
    * eval prepararEstado('Iniciar Pedido,Sin Ingredientes')
    # Y el técnico recarga los insumos faltantes
    # Cuando el sistema procesa el evento Recargar y Reiniciar
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Recargar y Reiniciar' }
    When method post
    # Entonces el estado cambia a En Espera y el robot queda disponible para nuevos pedidos
    Then status 200
    And match response.valida == true
    And match response.estadoNuevo == '#regex .*En Espera.*'
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*En Espera.*'

  # ---------------------------------------------------------------------------
  # TRANSICIONES INVÁLIDAS
  # ---------------------------------------------------------------------------

  @Issue-5 @req_transiciones_invalidas
  Scenario Outline: Rechazar el evento <evento_invalido> cuando el robot está en <estado_actual>
    # Dado que el sistema está en el estado <estado_actual>
    * eval prepararEstado('<pasos_previos>')
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*<estado_actual>.*'
    # Cuando se intenta procesar el evento <evento_invalido>
    Given path 'barista-bot/evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: '<evento_invalido>' }
    When method post
    # Entonces la API responde 200 pero marca la transición como inválida y NO cambia de estado
    Then status 200
    And match response.valida == false
    And match response.estadoNuevo == '#regex .*<estado_actual>.*'
    Given path 'barista-bot/estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#regex .*<estado_actual>.*'

    Examples:
      | estado_actual    | pasos_previos                    | evento_invalido   |
      | Moliendo         | Iniciar Pedido                   | Iniciar Pedido    |
      | Error de Insumos | Iniciar Pedido,Sin Ingredientes  | Iniciar Pedido    |
      | En Espera        | ninguno                          | Terminar Molienda |
      | Calentando Agua  | Iniciar Pedido,Terminar Molienda | Terminar Llenado  |
