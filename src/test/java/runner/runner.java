package runner;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import com.intuit.karate.junit5.Karate;
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

public class runner {

    @Test
    void testParallel() {

        Results results = Runner.path("classpath:features")
                .reportDir("target/karate-reports") // reportes HTML de Karate
                .outputCucumberJson(true) // <--- AQUi SE CONFIGURA
                .parallel(1);             // Define el numero de hilos concurrentes

        // Asercion para asegurar que el build de Gradle/Maven falle si alguna prueba no pasa
        assertEquals(0, results.getFailCount(), results.getErrorMessages());

    }

}