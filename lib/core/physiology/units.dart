/// Unidades físicas como tipos propios, sin costo en ejecución.
///
/// Cada una se puede usar como un `double` (implementa `double`), pero un
/// `double` suelto —o una unidad distinta— no se puede pasar donde la API
/// pide una de ellas. Así el compilador impide, por ejemplo, entregar
/// cadencia donde se espera potencia.
library;

/// Potencia en vatios.
extension type const Watts(double value) implements double {}

/// Energía o trabajo en julios.
extension type const Joules(double value) implements double {}

/// Cadencia en revoluciones por minuto.
extension type const Rpm(double value) implements double {}

/// Frecuencia cardíaca en latidos por minuto.
extension type const Bpm(double value) implements double {}

/// Torque en newton-metro.
extension type const NewtonMeters(double value) implements double {}
