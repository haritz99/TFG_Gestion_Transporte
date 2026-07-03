import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'sidebar_item.dart';

class AppSidebar extends StatelessWidget {
  final List<SidebarItem> navItems;

  const AppSidebar({super.key, required this.navItems});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final nombreEmpresa = context.read<AuthProvider>().company!.nombre;
    return Container(
      // Container principal
      width: 250,
      color: AppColors.surface,
      child: Column(
        // Columna principal que guarda el contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La columna principal contiene el header del sidebar, los items y el footer
          _buildSideBarHeader(nombreEmpresa),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'NAVEGACIÓN',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            // Aquí van los items principales del sidebar
            child: ListView(
              padding: EdgeInsets.zero,
              children: navItems,
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildFooter(context, user),
        ],
      ),
    );
  }

  Widget _buildSideBarHeader(String nombreEmpresa) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Contiene el icono y el nombre de la app
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreEmpresa,
                style: const TextStyle(
                  color: AppColors.titleText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, user) {
    // Contiene el avatar, nombre del usuario y el boton para logout
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            // Dentro de este row van el avagar y el nombre del usuario
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 18,
                child: Text(
                  user?.nombre.isNotEmpty == true ? user!.nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user?.nombre ?? 'Usuario'} ${user?.apellido ?? ''}'.trim(),
                      style: const TextStyle(
                        color: AppColors.titleText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.rol.join(', ') ?? 'Rol desconocido',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.mutedText, size: 20),
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                },
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

