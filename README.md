# Automatización de pruebas backend con Karate Framework

Taller de pruebas de caja negra con **Karate + Gherkin**, **Gradle/JUnit 5** y **GitHub Actions**, con trazabilidad por **GitHub Issues**.

| Bloque | Ejercicio | Archivo | Issues |
|---|---|---|---|
| Transición de estados | 1.2 Barista Bot | `src/test/resources/features/barista_bot.feature` | #1 a #5 |
| Tablas de decisión | 2.2 Controlador de Climatización Inteligente | `src/test/resources/features/climatizacion.feature` | #6 a #10 |

- `src/test/resources/helpers/barista-evento.feature`: utilitario reutilizable (no es un caso de prueba).
- `src/test/resources/karate-config.js`: define `baseUrl` y timeouts.
- `docs/trazabilidad.md`: requisito, escenario, tag e Issue.
- `docs/crear-issues.ps1`: crea los 10 Issues con `gh`.

## Ejecutar

```
.\gradlew.bat clean test
.\gradlew.bat test "-Dkarate.options=--tags @Issue-3"
```

Reporte: `target/karate-reports/karate-summary.html`.

## GitHub Actions

Se ejecuta en cada push (tag `@smoketest`) y manualmente por tag desde Actions, CI / CD Pipeline, Run workflow (`@Issue-N`). En ejecución manual comenta el Issue y actualiza su label `status:passed` / `status:failed`.
