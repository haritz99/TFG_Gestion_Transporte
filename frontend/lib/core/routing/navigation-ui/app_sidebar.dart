import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'sidebar_item.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = context.read<AuthProvider>().user;

    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSideBarHeader(),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SidebarItem(
                  title: 'Panel de Control',
                  icon: Icons.grid_view_rounded,
                  route: '/panel',
                  isSelected: location == '/panel',
                ),
                SidebarItem(
                  title: 'Gestión de Flota',
                  icon: Icons.local_shipping_outlined,
                  route: '/flota',
                  isSelected: location == '/flota',
                ),
                SidebarItem(
                  title: 'Gestión de Equipo',
                  icon: Icons.people_outline,
                  route: '/equipo',
                  isSelected: location == '/equipo',
                ),
                SidebarItem(
                  title: 'Centro de Incidencias',
                  icon: Icons.warning_amber_rounded,
                  route: '/incidencias',
                  isSelected: location == '/incidencias',
                  badgeCount: 0,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildFooter(context, user),
        ],
      ),
    );
  }

  Widget _buildSideBarHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre',
                style: TextStyle(
                  color: AppColors.titleText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Panel del Encargado',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
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

