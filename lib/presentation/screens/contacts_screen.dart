import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/emergency_contact.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final Box<EmergencyContact> _contactsBox = Hive.box<EmergencyContact>('contacts');

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Emergency Contact', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: AppColors.textDim),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g. + or local)',
                labelStyle: TextStyle(color: AppColors.textDim),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
              
              final newContact = EmergencyContact(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                role: 'family',
              );
              
              _contactsBox.add(newContact);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder(
        valueListenable: _contactsBox.listenable(),
        builder: (context, Box<EmergencyContact> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text(
                'No emergency contacts yet.\nPress + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, fontFamily: 'monospace'),
              ),
            );
          }

          final contacts = box.values.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Dismissible(
                key: Key(contact.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => contact.delete(),
                child: Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.green.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppColors.green),
                    ),
                    title: Text(contact.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(contact.phone, style: const TextStyle(color: AppColors.textDim, fontFamily: 'monospace')),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add, color: AppColors.bg),
      ),
    );
  }
}
