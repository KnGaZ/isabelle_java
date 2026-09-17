package mx.isabellabacalar;

import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

/**
 * Habilita el despliegue como WAR en un contenedor externo (WildFly).
 * WildFly detecta esta clase y arranca la app Spring dentro del servidor.
 */
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(IsabellaApplication.class);
    }
}
