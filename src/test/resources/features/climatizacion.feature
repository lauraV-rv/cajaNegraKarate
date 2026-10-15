@api @climatizacion @tabla_decision
Feature: Controlador de Climatización Inteligente (Smart Home) - Tabla de decisión
  Como habitante de una casa inteligente
  Quiero que el termostato decida la acción de climatización según el ambiente
  Para ahorrar energía y mantener el confort sin riesgos

  # Orden del arreglo "valores" que espera la API:
  #   [ C1: Temperatura > 26°C , C2: Presencia humana , C3: Ventana abierta > 3 min ]
  #
  # Reglas de decisión:
  #   R1: C3 = T (sin importar C1 y C2)        -> Apagar sistema de climatización y emitir alerta sonora
  #   R2: C1 = T, C2 = T, C3 = F               -> Encender aire acondicionado en modo refrigeración
  #   R3: C1 = T, C2 = F, C3 = F               -> Mantener en modo de bajo consumo energético
  #   R4: C1 = F, C3 = F (sin importar C2)     -> Mantener sistema apagado

  Background:
    * url baseUrl
    # Reinicio obligatorio del historial: cada escenario (y cada fila de Examples) es independiente
    Given path 'decision/climatizacion/reiniciar'
    And header Accept = 'application/json'
    When method post
    Then status 200

  @Issue-6 @smoketest @regla1 @req_apagar_y_alertar
  Scenario Outline: R1 - Ventana abierta (temp=<temperatura_alta>, presencia=<presencia_humana>) apaga la climatización y alerta
    # Dado que el sistema de climatización está monitoreando la habitación
    # Y la temperatura superior a 26°C es <temperatura_alta>
    # Y la presencia humana es <presencia_humana>
    # Y la ventana o puerta abierta por más de 3 minutos es <ventana_abierta>
    # Cuando el sistema evalúe las variables ambientales
    # Entonces el sistema apaga la climatización y emite una alerta sonora
    Given path 'decision/climatizacion/evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { valores: [<temperatura_alta>, <presencia_humana>, <ventana_abierta>] }
    When method post
    Then status 200
    # La API puede responder el texto plano o un objeto { accion, reglaIndex, ... }: se soportan ambos
    * def accion = karate.typeOf(response) == 'string' ? response : response.accion
    * match accion == '<accion_esperada>'

    Examples:
      | temperatura_alta | presencia_humana | ventana_abierta | accion_esperada                                         |
      | true             | true             | true            | Apagar sistema de climatización y emitir alerta sonora  |
      | true             | false            | true            | Apagar sistema de climatización y emitir alerta sonora  |
      | false            | true             | true            | Apagar sistema de climatización y emitir alerta sonora  |
      | false            | false            | true            | Apagar sistema de climatización y emitir alerta sonora  |

  @Issue-7 @regla2 @req_refrigeracion
  Scenario Outline: R2 - Temperatura alta con presencia y ventanas cerradas enciende la refrigeración
    # Dado que la temperatura interior es superior a 26°C
    # Y se detecta presencia humana activa en la habitación
    # Y las ventanas y puertas principales están cerradas
    # Cuando el sistema evalúe las variables ambientales
    # Entonces el sistema enciende el aire acondicionado en modo refrigeración
    Given path 'decision/climatizacion/evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { valores: [<temperatura_alta>, <presencia_humana>, <ventana_abierta>] }
    When method post
    Then status 200
    # La API puede responder el texto plano o un objeto { accion, reglaIndex, ... }: se soportan ambos
    * def accion = karate.typeOf(response) == 'string' ? response : response.accion
    * match accion == '<accion_esperada>'

    Examples:
      | temperatura_alta | presencia_humana | ventana_abierta | accion_esperada                                  |
      | true             | true             | false           | Encender aire acondicionado en modo refrigeración |

  @Issue-8 @regla3 @req_bajo_consumo
  Scenario Outline: R3 - Temperatura alta sin presencia y ventanas cerradas mantiene el bajo consumo
    # Dado que la temperatura interior es superior a 26°C
    # Y no se detecta presencia humana en la habitación
    # Y las ventanas y puertas principales están cerradas
    # Cuando el sistema evalúe las variables ambientales
    # Entonces el sistema se mantiene en modo de bajo consumo energético
    Given path 'decision/climatizacion/evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { valores: [<temperatura_alta>, <presencia_humana>, <ventana_abierta>] }
    When method post
    Then status 200
    # La API puede responder el texto plano o un objeto { accion, reglaIndex, ... }: se soportan ambos
    * def accion = karate.typeOf(response) == 'string' ? response : response.accion
    * match accion == '<accion_esperada>'

    Examples:
      | temperatura_alta | presencia_humana | ventana_abierta | accion_esperada                             |
      | true             | false            | false           | Mantener en modo de bajo consumo energético |

  @Issue-9 @regla4 @req_mantener_apagado
  Scenario Outline: R4 - Temperatura normal con ventanas cerradas (presencia=<presencia_humana>) mantiene el sistema apagado
    # Dado que la temperatura interior es de 26°C o menos
    # Y la presencia humana es <presencia_humana>
    # Y las ventanas y puertas principales están cerradas
    # Cuando el sistema evalúe las variables ambientales
    # Entonces el sistema se mantiene apagado
    Given path 'decision/climatizacion/evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { valores: [<temperatura_alta>, <presencia_humana>, <ventana_abierta>] }
    When method post
    Then status 200
    # La API puede responder el texto plano o un objeto { accion, reglaIndex, ... }: se soportan ambos
    * def accion = karate.typeOf(response) == 'string' ? response : response.accion
    * match accion == '<accion_esperada>'

    Examples:
      | temperatura_alta | presencia_humana | ventana_abierta | accion_esperada           |
      | false            | true             | false           | Mantener sistema apagado  |
      | false            | false            | false           | Mantener sistema apagado  |

  @Issue-10 @req_consulta_definicion_historial
  Scenario: Consultar la definición del controlador después de evaluar una regla
    # Dado que se evalúa una regla (temperatura alta, con presencia y ventanas cerradas)
    Given path 'decision/climatizacion/evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { valores: [true, true, false] }
    When method post
    Then status 200
    * def accion = karate.typeOf(response) == 'string' ? response : response.accion
    * match accion == 'Encender aire acondicionado en modo refrigeración'
    # Cuando se consulta la definición (condiciones + historial)
    Given path 'decision/climatizacion/definicion'
    And header Accept = 'application/json'
    When method get
    # Entonces la API responde con la definición del controlador
    Then status 200
    And match response == '#notnull'
    * print 'Definición e historial del controlador:', response
