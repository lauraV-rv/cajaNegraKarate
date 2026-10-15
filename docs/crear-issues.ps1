# Crea los 10 Issues de trazabilidad con GitHub CLI (gh). Requiere: gh auth login
# Ejecutar desde la raíz del repositorio. Si el repo ya tiene Issues, los números NO coincidirán con los tags.
$f = "src/test/resources/features"
$issues = @(
  @("[API][Barista Bot] Iniciar pedido: En Espera a Moliendo","@Issue-1","$f/barista_bot.feature","@req_iniciar_pedido"),
  @("[API][Barista Bot] Flujo completo hasta volver a En Espera","@Issue-2","$f/barista_bot.feature","@req_flujo_completo_pedido"),
  @("[API][Barista Bot] Sin Ingredientes lleva a Error de Insumos","@Issue-3","$f/barista_bot.feature","@req_sin_ingredientes"),
  @("[API][Barista Bot] Recargar y Reiniciar vuelve a En Espera","@Issue-4","$f/barista_bot.feature","@req_recarga_reinicio"),
  @("[API][Barista Bot] Rechazar transiciones inválidas","@Issue-5","$f/barista_bot.feature","@req_transiciones_invalidas"),
  @("[API][Climatización] R1 Ventana abierta apaga y alerta","@Issue-6","$f/climatizacion.feature","@req_apagar_y_alertar"),
  @("[API][Climatización] R2 Refrigeración","@Issue-7","$f/climatizacion.feature","@req_refrigeracion"),
  @("[API][Climatización] R3 Bajo consumo","@Issue-8","$f/climatizacion.feature","@req_bajo_consumo"),
  @("[API][Climatización] R4 Mantener apagado","@Issue-9","$f/climatizacion.feature","@req_mantener_apagado"),
  @("[API][Climatización] Consultar definición e historial","@Issue-10","$f/climatizacion.feature","@req_consulta_definicion_historial")
)
foreach ($i in $issues) {
  $body = "## Trazabilidad de Automatización`n- Tag Karate: ``$($i[1])```n- Archivo Feature: ``$($i[2])```n- Requisito: ``$($i[3])``"
  gh issue create --title $i[0] --body $body
}
