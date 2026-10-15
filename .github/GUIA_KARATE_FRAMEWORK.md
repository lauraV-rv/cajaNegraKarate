# Guía de uso de Karate Framework

## 1. Introducción

Karate Framework es una herramienta de automatización orientada principalmente a pruebas de APIs, aunque también soporta UI testing, performance y mocks.  
Su principal ventaja es que permite escribir pruebas en una sintaxis muy simple, legible y cercana a Gherkin, sin necesidad de construir una gran cantidad de código Java.

Con Karate es posible:

- consumir servicios REST
- validar códigos de estado
- validar estructuras JSON y XML
- encadenar peticiones
- reutilizar autenticación
- parametrizar ambientes
- ejecutar pruebas con Gradle o desde IntelliJ

---

## 2. Prerrequisitos

Antes de comenzar, se recomienda tener instalado:

- **Java 17** o superior
- **IntelliJ IDEA**
- **Gradle** o uso del wrapper `gradlew`
- conexión a internet para descargar dependencias Maven

Para verificar Java:

```bash
java -version
```

---

## 3. Creación del proyecto

Una estructura mínima recomendada para un proyecto Karate es la siguiente:

```text
karate-api-tests/
├── build.gradle
├── settings.gradle
└── src
    └── test
        ├── java
        │   └── runners
        │       └── KarateTestRunner.java
        └── resources
            ├── karate-config.js
            └── features
                ├── auth.feature
                └── users.feature
```

---

## 4. Configuración de Gradle

Archivo `build.gradle` mínimo:

```gradle
plugins {
    id 'java'
}

group = 'com.example'
version = '1.0.0'

repositories {
    mavenCentral()
}

ext {
    karateVersion = '1.4.1'
}

dependencies {
    testImplementation "com.intuit.karate:karate-junit5:${karateVersion}"
    testImplementation "ch.qos.logback:logback-classic:1.5.6"
}

test {
    useJUnitPlatform()
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}
```

Archivo `settings.gradle`:

```gradle
rootProject.name = 'karate-api-tests'
```

---

## 5. Configuración en IntelliJ

### 5.1 Importar proyecto
1. Abrir IntelliJ IDEA
2. Seleccionar **Open**
3. Elegir la carpeta raíz del proyecto
4. Esperar a que Gradle descargue dependencias

### 5.2 Plugins recomendados
Instalar desde IntelliJ Marketplace:

- **Gherkin**
- **Cucumber for Java**

Estos plugins mejoran el resaltado y la edición de archivos `.feature`.

### 5.3 Estructura correcta de recursos
Los archivos `.feature` deben ubicarse normalmente en:

```text
src/test/resources/features/
```

Y los runners Java en:

```text
src/test/java/runners/
```

---

## 6. Primer runner de Karate

Crear la clase:

```java
package runners;

import com.intuit.karate.junit5.Karate;

public class KarateTestRunner {

    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:features").relativeTo(getClass());
    }
}
```

Esta clase permite ejecutar todos los features dentro de la carpeta `features`.

---

## 7. Primer feature

Archivo `src/test/resources/features/users.feature`:

```gherkin
Feature: Prueba básica de API

  Scenario: Consultar usuarios
    Given url 'https://reqres.in/api/users?page=2'
    When method get
    Then status 200
    * print response
```

### Explicación
- `Feature`: describe el módulo o funcionalidad
- `Scenario`: describe el caso de prueba
- `Given url`: define la URL objetivo
- `When method get`: ejecuta el GET
- `Then status 200`: valida el status code
- `print response`: imprime el body de la respuesta

---

## 8. Sintaxis básica de Karate

### 8.1 Definición de variables
```gherkin
* def name = 'Juan'
* def age = 30
```

### 8.2 Impresión de variables
```gherkin
* print 'name =>', name
```

### 8.3 Request body JSON
```gherkin
* def requestBody =
"""
{
  "name": "morpheus",
  "job": "leader"
}
"""
```

### 8.4 Envío de request body
```gherkin
And request requestBody
```

### 8.5 Validación de campos
```gherkin
And match response.name == 'morpheus'
```

---

## 9. Ejemplo de petición POST

```gherkin
Feature: Crear usuario

  Scenario: Crear usuario exitosamente
    Given url 'https://reqres.in/api/users'
    And request
    """
    {
      "name": "morpheus",
      "job": "leader"
    }
    """
    When method post
    Then status 201
    * print 'response =>', karate.pretty(response)
```

---

## 10. Headers

### Header individual
```gherkin
And header Content-Type = 'application/json'
```

### Varios headers
```gherkin
And headers { Accept: 'application/json', Content-Type: 'application/json' }
```

---

## 11. Query params

```gherkin
Given url 'https://reqres.in/api/users'
And param page = 2
When method get
Then status 200
```

---

## 12. Path params

```gherkin
Given url 'https://reqres.in'
And path 'api', 'users', 2
When method get
Then status 200
```

Esto genera la URL:

```text
https://reqres.in/api/users/2
```

---

## 13. Form fields

Para peticiones `application/x-www-form-urlencoded`:

```gherkin
Given url 'https://example.com/oauth/token'
And header Content-Type = 'application/x-www-form-urlencoded'
And form field username = 'usuario'
And form field password = 'clave'
And form field grant_type = 'password'
When method post
Then status 200
```

---

## 14. Uso de `karate-config.js`

Karate ejecuta automáticamente el archivo `karate-config.js` al inicio de cada feature.  
Sirve para:

- definir variables globales
- parametrizar ambientes
- centralizar URLs
- configurar autenticación

Ejemplo:

```javascript
function fn() {
  var config = {
    baseUrl: 'https://reqres.in',
    env: karate.env || 'dev'
  };

  return config;
}
```

Luego en un feature:

```gherkin
Feature: Variables globales

  Scenario: usar baseUrl
    Given url baseUrl
    And path 'api', 'users'
    When method get
    Then status 200
```

---

## 15. Variables por línea de comando con Gradle

En `build.gradle`:

```gradle
test {
    useJUnitPlatform()
    systemProperty "base_url", System.getProperty("base_url")
}
```

En `karate-config.js`:

```javascript
function fn() {
  return {
    baseUrl: karate.properties['base_url']
  };
}
```

Ejecución:

```bash
./gradlew test -Dbase_url=https://reqres.in
```

---

## 16. Reutilización de autenticación

### `auth.feature`
```gherkin
Feature: autenticación

  Scenario: obtener token
    Given url urlAuth
    And path 'oauth', 'token'
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field username = username
    And form field password = password
    And form field grant_type = 'password'
    When method post
    Then status 200
    * def token = response.access_token
```

### `karate-config.js`
```javascript
function fn() {
  var config = {
    urlAuth: karate.properties['url_auth'],
    urlApi: karate.properties['url_api'],
    username: karate.properties['username'],
    password: karate.properties['password']
  };

  var auth = karate.callSingle('classpath:features/auth.feature', config);
  config.token = auth.token;

  karate.configure('headers', function() {
    return {
      Authorization: 'Bearer ' + config.token,
      Accept: 'application/json'
    };
  });

  return config;
}
```

Con esto, todos los features pueden usar el token automáticamente.

---

## 17. Compartir datos entre peticiones

Ejemplo: usar un valor de un GET en un POST.

```gherkin
Feature: Encadenar requests

  Background:
    * url 'https://reqres.in'

  Scenario: obtener dato y reutilizarlo
    Given path 'api', 'users', 2
    When method get
    Then status 200

    * def firstName = response.data.first_name

    * def requestBody =
    """
    {
      "name": "#(firstName)",
      "job": "leader"
    }
    """

    Given path 'api', 'users'
    And request requestBody
    When method post
    Then status 201
```

---

## 18. Manejo de arrays

Si la respuesta contiene un array:

```json
{
  "items": [
    { "id": 1, "type": "A" },
    { "id": 2, "type": "B" }
  ]
}
```

puedes acceder así:

```gherkin
* def items = response.items
* print items[0].id
* print items[1].type
```

Validar que sea array:

```gherkin
* match response.items == '#[]'
```

---

## 19. Transformar arrays para otro request

```gherkin
* def items = response.items

* def mapper =
"""
function(items) {
  var out = [];
  for (var i = 0; i < items.length; i++) {
    out.push({
      itemId: items[i].id,
      status: 'PENDING'
    });
  }
  return out;
}
"""

* def details = mapper(items)

* def requestBody =
"""
{
  "operation": "PROCESS",
  "details": "#(details)"
}
"""
```

---

## 20. Uso de archivos JSON externos

Guardar payload en:

`src/test/resources/data/request/create-user.json`

```json
{
  "name": "morpheus",
  "job": "leader"
}
```

Usarlo en el feature:

```gherkin
* def requestBody = read('classpath:data/request/create-user.json')
Given url 'https://reqres.in/api/users'
And request requestBody
When method post
Then status 201
```

---

## 21. Pretty print de JSON

Si quieres imprimir JSON formateado:

```gherkin
* print karate.pretty(response)
```

Si tienes un texto JSON:

```gherkin
* def jsonText = '{"name":"Juan","age":30}'
* def jsonObj = karate.fromString(jsonText)
* print karate.pretty(jsonObj)
```

---

## 22. Debug básico

### Imprimir variables
```gherkin
* print 'token =>', token
* print 'response =>', karate.pretty(response)
```

### Verificar tipo
```gherkin
* print karate.typeOf(response)
```

### Ver request/response pretty
```gherkin
* configure logPrettyRequest = true
* configure logPrettyResponse = true
```

**Nota:** no se recomienda dejar esto activo si se envían secretos en headers.

---

## 23. Manejo seguro de secretos en logs

Ejemplo para ofuscar token:

```gherkin
* def maskSecret =
"""
function(value) {
  if (!value) return '[NULL]';
  var s = String(value);
  if (s.length <= 10) return '********';
  return s.substring(0, 4) + '...' + s.substring(s.length - 4);
}
"""
* print 'token preview =>', maskSecret(token)
```

---

## 24. Buenas prácticas

- separar features por dominio funcional
- centralizar autenticación
- usar `karate-config.js` para variables globales
- reutilizar payloads con archivos JSON
- no imprimir secretos completos
- usar funciones JS para transformaciones complejas
- mantener features legibles y cortos
- validar siempre status y campos críticos del response

---

## 25. Errores comunes

### Error de sintaxis en headers
Incorrecto:
```gherkin
And header Content-Type: 'application/json'
```

Correcto:
```gherkin
And header Content-Type = 'application/json'
```

### Uso incorrecto de `return` en feature
Incorrecto:
```gherkin
* return result
```

Correcto:
```gherkin
* def token = response.access_token
```

### Variables entre comillas
Incorrecto:
```gherkin
Given url 'baseUrl'
```

Correcto:
```gherkin
Given url baseUrl
```

---

## 26. Ejecución

### Desde IntelliJ
- clic derecho sobre el runner
- seleccionar **Run** o **Debug**

### Desde Gradle
```bash
./gradlew test
```

Con variables:
```bash
./gradlew test -Durl_api=https://reqres.in -Dusername=user -Dpassword=pass
```

---

## 27. Conclusión

Karate Framework permite construir automatizaciones API de forma rápida, legible y mantenible.  
Su mayor fortaleza está en combinar:

- sintaxis simple
- soporte nativo para JSON
- reutilización de features
- configuración flexible
- poco código Java

Para proyectos empresariales, se recomienda comenzar con una estructura simple, reutilizar autenticación, externalizar datos y usar funciones JS para transformaciones dinámicas.