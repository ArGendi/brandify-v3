import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('subusers')
        .get();
    setState(() {
      _users = query.docs.map((doc) => AppUser.fromJson(doc.data(), doc.id)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showUserBottomSheet({AppUser? user}) async {
    final isEdit = user != null;
    final _formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final privilegeKeyMap = {
      'view_sales': AppLocalizations.of(context)!.privilegeViewSales,
      'view_profit': AppLocalizations.of(context)!.privilegeViewProfit,
      'view_cost_price': AppLocalizations.of(context)!.privilegeViewCostPrice,
      'add_product': AppLocalizations.of(context)!.privilegeAddProduct,
      'edit_product': AppLocalizations.of(context)!.privilegeEditProduct,
      'delete_product': AppLocalizations.of(context)!.privilegeDeleteProduct,
      'view_reports': AppLocalizations.of(context)!.privilegeViewReports,
      'user_management': AppLocalizations.of(context)!.privilegeUserManagement,
    };
    final privilegesList = [
      'view_sales',
      'view_profit',
      'view_cost_price',
      'add_product',
      'edit_product',
      'delete_product',
      'view_reports',
      'user_management',
    ];
    List<String> selectedPrivileges = isEdit
      ? List<String>.from(user.privileges)
      : List<String>.from(privilegesList); // All checked by default for add
    bool isLoading = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 24
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isEdit ? AppLocalizations.of(context)!.editUser ?? 'Edit User' : AppLocalizations.of(context)!.addUser ?? 'Add User', // TODO: Add 'editUser' and 'addUser' to ARB files
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor),
                      ),
                      SizedBox(height: 20),
                      CustomTextFormField(
                        controller: usernameController,
                        text: AppLocalizations.of(context)!.username,
                        onSaved: (_) {},
                        onValidate: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.required ?? 'Required' : null, // TODO: Add 'required' to ARB files
                      ),
                      SizedBox(height: 15),
                      CustomTextFormField(
                        controller: passwordController,
                        text: AppLocalizations.of(context)!.password,
                        obscureText: true,
                        onSaved: (_) {},
                        onValidate: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.required ?? 'Required' : null,
                      ),
                      SizedBox(height: 15),
                      CustomTextFormField(
                        controller: phoneController,
                        text: AppLocalizations.of(context)!.phone ?? 'Phone', // TODO: Add 'phone' to ARB files
                        keyboardType: TextInputType.phone,
                        onSaved: (_) {},
                      ),
                      SizedBox(height: 20),
                      Text(AppLocalizations.of(context)!.privileges ?? 'Privileges', style: TextStyle(fontWeight: FontWeight.bold)), // TODO: Add 'privileges' to ARB files
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: privilegesList.map((priv) {
                          final selected = selectedPrivileges.contains(priv);
                          return FilterChip(
                            label: Text(privilegeKeyMap[priv] ?? priv),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedPrivileges.add(priv);
                                } else {
                                  selectedPrivileges.remove(priv);
                                }
                              });
                            },
                            selectedColor: mainColor.withOpacity(0.15),
                            checkmarkColor: mainColor,
                          );
                        }).toList(),
                      ),
                      if (isLoading) ...[
                        SizedBox(height: 20),
                        Center(child: CircularProgressIndicator()),
                      ],
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(AppLocalizations.of(context)!.cancel ?? 'Cancel'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        setState(() => isLoading = true);
                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        if (currentUser == null) return;
                                        if (isEdit) {
                                          await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .collection('subusers')
                                            .doc(user.id)
                                            .update({
                                              'privileges': selectedPrivileges,
                                              'username': usernameController.text.trim(),
                                              'password': passwordController.text.trim(),
                                              'phone': phoneController.text.trim(),
                                            });
                                        } else {
                                          await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .collection('subusers')
                                            .add({
                                              'username': usernameController.text.trim(),
                                              'privileges': selectedPrivileges,
                                              'password': passwordController.text.trim(),
                                              'phone': phoneController.text.trim(),
                                            });
                                        }
                                        setState(() => isLoading = false);
                                        Navigator.pop(context);
                                        _fetchUsers();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isEdit ? AppLocalizations.of(context)!.userUpdated ?? 'User updated!' : AppLocalizations.of(context)!.userAdded ?? 'User added!')), // TODO: Add 'userUpdated' and 'userAdded' to ARB files
                                        );
                                      }
                                    },
                              child: Text(isEdit ? AppLocalizations.of(context)!.save ?? 'Save' : AppLocalizations.of(context)!.add ?? 'Add'), // TODO: Add 'save' and 'add' to ARB files
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('subusers')
      .doc(userId)
      .delete();
    _fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.userDeleted ?? 'User deleted.')), // TODO: Add 'userDeleted' to ARB files
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userManagement ?? 'User Management'), // TODO: Add 'userManagement' to ARB files
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _users.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline, size: 60, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noUsersYet ?? 'No users yet.', // TODO: Add 'noUsersYet' to ARB files
                                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.createUserFirst ?? 'Create a user for yourself first (with all privileges enabled) before adding other users.', // TODO: Add 'createUserFirst' to ARB files
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, i) {
                              final user = _users[i];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ),
                                  title: Text(user.username, style: TextStyle(fontWeight: FontWeight.w600)),
                                  // subtitle: Wrap(
                                  //   spacing: 6,
                                  //   children: user.privileges.map((p) => Text("${p.replaceAll('_', ' ')},")).toList(),
                                  // ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showUserBottomSheet(user: user),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteUser(user.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ),
                ),
                
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.person_add),
        label: Text(AppLocalizations.of(context)!.addUser ?? 'Add User'), // TODO: Add 'addUser' to ARB files
        onPressed: () => _showUserBottomSheet(),
      ),
    );
  }
} 