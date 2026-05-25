import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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

  Future<void> _pickFromPhoneContacts(
    StateSetter setState,
    TextEditingController nameCtrl,
    TextEditingController phoneCtrl,
  ) async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status == PermissionStatus.granted) {
        final contact = await FlutterContacts.native.showPicker();
        if (contact != null) {
          final contactId = contact.id;
          if (contactId != null) {
            final fullContact = await FlutterContacts.get(
              contactId,
              properties: {ContactProperty.name, ContactProperty.phone},
            );
            if (fullContact != null) {
              final name = fullContact.displayName;
              String rawPhone = fullContact.phones.isNotEmpty 
                  ? fullContact.phones.first.number 
                  : '';
              
              // Basic cleanup for formatting artifacts
              String phone = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              
              setState(() {
                nameCtrl.text = name ?? '';
                phoneCtrl.text = phone;
              });
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required to import from phone.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read contacts: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'family';
    bool isPrimary = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('Add Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green.withValues(alpha: 0.1),
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.import_contacts_outlined, size: 18),
                    label: const Text(
                      'IMPORT FROM PHONE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () => _pickFromPhoneContacts(setState, nameController, phoneController),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR ENTER MANUALLY', style: TextStyle(color: AppColors.textDim, fontSize: 8, fontFamily: 'monospace')),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Role / Relationship',
                    labelStyle: TextStyle(color: AppColors.textDim),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(value: 'rescue', child: Text('Rescue Service')),
                    DropdownMenuItem(value: 'sar', child: Text('Search & Rescue')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Primary Contact', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: const Text('First number to receive emergency texts', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  value: isPrimary,
                  activeThumbColor: AppColors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => isPrimary = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
                
                final newContact = EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  role: selectedRole,
                  isPrimary: isPrimary,
                );
                
                await _contactsBox.add(newContact);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(EmergencyContact contact) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    String selectedRole = contact.role;
    bool isPrimary = contact.isPrimary;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text('Edit Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green.withValues(alpha: 0.1),
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.import_contacts_outlined, size: 18),
                    label: const Text(
                      'IMPORT FROM PHONE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () => _pickFromPhoneContacts(setState, nameController, phoneController),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR UPDATE DETAILS', style: TextStyle(color: AppColors.textDim, fontSize: 8, fontFamily: 'monospace')),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Role / Relationship',
                    labelStyle: TextStyle(color: AppColors.textDim),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'friend', child: Text('Friend')),
                    DropdownMenuItem(value: 'rescue', child: Text('Rescue Service')),
                    DropdownMenuItem(value: 'sar', child: Text('Search & Rescue')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Primary Contact', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: const Text('First number to receive emergency texts', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  value: isPrimary,
                  activeThumbColor: AppColors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => isPrimary = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
                
                contact.name = nameController.text.trim();
                contact.phone = phoneController.text.trim();
                contact.role = selectedRole;
                contact.isPrimary = isPrimary;
                await contact.save();
                
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(EmergencyContact contact) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${contact.name}?', style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'rescue':
        return Icons.local_hospital;
      case 'sar':
        return Icons.health_and_safety;
      case 'friend':
        return Icons.people;
      case 'family':
      default:
        return Icons.person;
    }
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'rescue':
      case 'sar':
        return AppColors.red;
      case 'friend':
        return AppColors.orange;
      case 'family':
      default:
        return AppColors.green;
    }
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
              final roleColor = _getColorForRole(contact.role);
              final roleIcon = _getIconForRole(contact.role);

              return Dismissible(
                key: Key(contact.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _showDeleteConfirmationDialog(contact),
                onDismissed: (_) => contact.delete(),
                child: Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.1),
                      child: Icon(roleIcon, color: roleColor),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(contact.phone, style: const TextStyle(color: AppColors.textDim, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            contact.role.toUpperCase(),
                            style: TextStyle(color: roleColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.green, size: 20),
                          onPressed: () => _showEditContactDialog(contact),
                          tooltip: 'Edit contact',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                          onPressed: () async {
                            final confirm = await _showDeleteConfirmationDialog(contact);
                            if (confirm == true) {
                              await contact.delete();
                            }
                          },
                          tooltip: 'Delete contact',
                        ),
                      ],
                    ),
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
