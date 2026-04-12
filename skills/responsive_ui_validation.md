# Responsive UI Validation Skill

## Contexto
Esta skill se utiliza para asegurar la calidad de componentes UI construidos en Flutter, asegurando que sean aptos de forma óptima para Web (escritorio) y Móvil simultáneamente, y que la modularidad/integración de código cumpla los estándares del proyecto.

## Checklist de Validación Arquitectónica

### 1. Layout Responsivo
- [ ] **Estructuras Adaptativas:** Comprueba que en móvil las tablas complejas muten hacia layouts verticales tipo Tarjetas integradas (List o Cards) y evites el Scroll horizontal puro para lectura de filas a menos que sea inevitable.
- [ ] **Breakpoints únicos:** El LayoutBuilder o MediaQuery se implementa en la vista principal o contenedor (padre de la Page). Variables como `isMobile` (ej: `maxWidth < 900`) se inyectan en los hijos.
- [ ] **Aprovechamiento Web:** Los componentes Web no deben estar limitados por contenedores con `width` absolutos rígidos (ej. no usar `SizedBox(width: 1440)` como raíz de todo). Se deben usar `Expanded`, `Flexible`, `ConstrainedBox`, o `DataTable` para adaptarse al monitor (que podría ser más de 900px pero menos de 1440).

### 2. Principio DRY - Evitar Números Mágicos (Redundancia)
- [ ] **Mapeo de Columnas Desacoplado:** Si construyes vistas tipo fila-columna a mano, los anchors y pesos (`Flex`) de las columnas NUNCA deben escribirse hardcodeados varias veces en celdas o cabeceras diferentes. Utiliza una configuración compartida o constantes (ej: `List<ColumnDefinition>`).

### 3. Modularización
- [ ] **Archivos separados por dominio:** Verifica que KPIs, Headers, y listados pesados se extraen a archivos en subdirectorios `**/ui/widgets/`.
- [ ] **Separación BLoC/Estado:** Las Vistas (`Page`) con LayoutBuilder son puras (`StatelessWidget` o `Stateful` sin lógica de BBDD). La lógica de red o proveeduría reside en su `Screen` respectiva.
