# Trazabilidad: requisito -> escenario -> tag -> Issue

| Issue | Ejercicio | Escenario (Karate) | Tag de requisito | Archivo |
|---|---|---|---|---|
| #1 | Barista Bot (transición de estados) | Iniciar pedido: En Espera -> Moliendo | `@req_iniciar_pedido` | `features/barista_bot.feature` |
| #2 | Barista Bot | Flujo completo hasta volver a En Espera | `@req_flujo_completo_pedido` | `features/barista_bot.feature` |
| #3 | Barista Bot | Sin Ingredientes -> Error de Insumos (3 estados, Outline) | `@req_sin_ingredientes` | `features/barista_bot.feature` |
| #4 | Barista Bot | Recargar y Reiniciar -> En Espera | `@req_recarga_reinicio` | `features/barista_bot.feature` |
| #5 | Barista Bot | Rechazar transiciones inválidas (4 casos, Outline) | `@req_transiciones_invalidas` | `features/barista_bot.feature` |
| #6 | Climatización (tabla de decisión) | R1 ventana abierta: apagar y alertar (4 combinaciones) | `@req_apagar_y_alertar` | `features/climatizacion.feature` |
| #7 | Climatización | R2 refrigeración | `@req_refrigeracion` | `features/climatizacion.feature` |
| #8 | Climatización | R3 bajo consumo | `@req_bajo_consumo` | `features/climatizacion.feature` |
| #9 | Climatización | R4 mantener apagado (2 combinaciones) | `@req_mantener_apagado` | `features/climatizacion.feature` |
| #10 | Climatización | Consultar definición e historial | `@req_consulta_definicion_historial` | `features/climatizacion.feature` |

El número del Issue en GitHub debe coincidir con el del tag `@Issue-N`: el pipeline lo extrae del tag para comentar y etiquetar el Issue.

## Ejecución por tag

```
.\gradlew.bat test "-Dkarate.options=--tags @Issue-3"
```

En GitHub: Actions -> CI / CD Pipeline -> Run workflow -> `@Issue-3`.
