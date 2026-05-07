import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/invite_provider.dart';

class GuestList extends StatelessWidget {
  const GuestList({super.key});

  @override
  Widget build(BuildContext context) {
    final inviteProvider = context.watch<InviteProvider>();
    final guests = inviteProvider.guests;
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (guests.isEmpty) {
      return const Center(
        child: Text('No hay invitados')
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: guests.length,
      itemBuilder: (context, index) {
        final guest = guests[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            guest.nombre,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guest.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (guest.createdAt != null)
                Text(
                  'Invitado el ${DateFormat('dd MMM yyyy').format(guest.createdAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              if (isMobile) ...[
                const SizedBox(height: 4),
                _buildRoleBadge(guest.rol[0]),
              ],
            ],
          ),
          trailing: SizedBox(
            width: isMobile ? 100 : 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isMobile) ...[
                  _buildRoleBadge(guest.rol[0]),
                  const SizedBox(width: 8),
                ],
                if (guest.datosCompletos == false)
                Tooltip(
                  message: 'Enviar email de invitación',
                  child: IconButton(
                    icon: const Icon(Icons.email_outlined, size: 20),
                    onPressed: () => inviteProvider.sendInviteEmail(guest.email, guest.rol[0]),
                    color: Colors.grey.shade600,
                  )
                ),
                Tooltip(
                  message: 'Dar de baja',
                  child: IconButton(
                    icon: const Icon(Icons.person_remove_outlined, size: 20),
                    onPressed: () {},
                    color: Colors.grey.shade600,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String rol) {
    final nombreRol = rol == 'cliente' ? 'CARGADOR' : 'SUBCONTRATADO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        nombreRol,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}