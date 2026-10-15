function fn() {
    var config = {
        env: karate.env || 'dev',
        baseUrl: 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/'
    };

    // Simplifica y formatea el JSON/XML de los Requests y Responses en la consola
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    // Render (plan gratuito) "duerme" el servicio y la primera petición puede tardar ~30-60 s
    karate.configure('connectTimeout', 60000);
    karate.configure('readTimeout', 60000);

    return config;
}
