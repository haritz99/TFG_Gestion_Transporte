A continuación, se muestran las principales funcionalidades del producto descrito:

## Para los encargados:

- Dar de alta a un transportista: El encargado será la persona responsable de registrar
	a los transportistas. Tanto a los transportistas propios del equipo como a los externos.
- Dar de baja a un transportista: Podrá dar de baja a un transportista en el sistema.
	Tanto a los transportistas propios del equipo como a los externos.
- Insertar vehiculo al sistema: Podrá insertar un vehiculo de la empresa al sistema,
	introduciendo los datos relevantes. Existen vehículos internos y externos.
- Asignar vehiculo: Podrá asignar un vehiculo a un transportista.
- Consultar disponibilidad de transportista: Podrá consultar la disponibilidad de
	cada transportista y sus entregas pendientes.
- Crear carga: Podrá crear una carga introduciendo los detalles de la misma y asignarla
	a un transportista.
- Generar carta de porte: Podrá generar una carta de porte y asignarla a la carga
	correspondiente.
- Asignar tarea de mantenimiento: Podrá asignar una tarea de mantenimiento junto
	con sus detalles a un transportista.
- Visualizar incidencias: Podrá visualizar todas las incidencias activas registradas.


## Para los transportistas:

- Conocer cantidad de cargas asignadas: Podrá solicitar la cantidad de cargas que
	tiene asignadas y sus destinos.
- Conocer la siguiente entrega: Podrá solicitar la siguiente entrega.
- Consultar detalles de una carga: Podrá solicitar los detalles de una carga, como peso,
	tipo de mercancia o instrucciones especiales.
- Confirmar recogida: Podrá confirmar la recogida de una carga en un origen concreto.
- Confirmar entrega: Podrá confirmar la entrega de una carga en un destino concreto.
- Reportar incidencia: Podrá reportar una incidencia con los detalles de la misma.
- Consultar tareas de mantenimiento pendientes: Podrá consultar las tareas de
	mantenimiento que tiene asignadas y que están pendientes de realizar.
- Visualizar ruta actual: La navegación será delegada a aplicaciones externas especializadas, dado que los conductores profesionales disponen de sistemas de navegación
	propios adaptados a vehículos de gran tonelaje.


org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true