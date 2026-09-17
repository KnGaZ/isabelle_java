package mx.isabellabacalar;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de entrada de la aplicacion Isabella Bacalar.
 *
 * Sirve tanto para correr embebido (mvn spring-boot:run / java -jar) como
 * para el despliegue WAR en WildFly (ver {@link ServletInitializer}).
 */
@SpringBootApplication
public class IsabellaApplication {

    public static void main(String[] args) {
        SpringApplication.run(IsabellaApplication.class, args);
    }
}
