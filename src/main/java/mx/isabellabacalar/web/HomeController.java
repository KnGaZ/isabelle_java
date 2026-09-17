package mx.isabellabacalar.web;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Controlador base de la Fase 1.
 *
 * Provee:
 *  - "/"        pagina de inicio con el layout, la paleta y el bottom nav.
 *  - "/salud"   verificacion de conexion a MySQL (SELECT 1).
 *
 * NOTA: mientras no exista Spring Security (Fase 3), el rol del usuario se
 * simula con un atributo del modelo. El bottom nav ya filtra por rol usando
 * ese atributo; en la Fase 3 solo se cambia la fuente (usuario autenticado).
 */
@Controller
public class HomeController {

    private final JdbcTemplate jdbcTemplate;

    public HomeController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /** Atributos que hoy simulan la sesion; en Fase 3 vendran del login. */
    private void poblarUsuarioDemo(Model model) {
        model.addAttribute("userName", "Vane");
        model.addAttribute("userRole", "ADMIN"); // ADMIN | GERENCIA | SOCIO | RECEPCION | CAMARISTA
    }

    @GetMapping("/")
    public String home(Model model) {
        poblarUsuarioDemo(model);
        model.addAttribute("active", "dashboard");
        return "index";
    }

    @GetMapping("/salud")
    public String salud(Model model) {
        poblarUsuarioDemo(model);
        model.addAttribute("active", "");
        String dbInfo;
        boolean ok;
        try {
            // Prueba minima de conectividad a la base.
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            dbInfo = jdbcTemplate.queryForObject("SELECT VERSION()", String.class);
            ok = true;
        } catch (Exception e) {
            dbInfo = e.getMessage();
            ok = false;
        }
        model.addAttribute("dbOk", ok);
        model.addAttribute("dbInfo", dbInfo);
        return "salud";
    }
}
