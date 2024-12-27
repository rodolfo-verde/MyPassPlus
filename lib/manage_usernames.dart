import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'generated/l10n.dart'; // Add this import
import 'username_manager.dart';

class ManageUsernamesScreen extends StatelessWidget {
  const ManageUsernamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameManager = Provider.of<UsernameManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).manageUsernames), // Localized string
      ),
      body: ListView.builder(
        itemCount: usernameManager.usernames.length,
        itemBuilder: (context, index) {
          String username = usernameManager.usernames[index];
          return ListTile(
            title: Text(username),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    TextEditingController editController =
                        TextEditingController(text: username);
                    String? errorMessage;
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: Text(S.of(context).editUsername),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: editController,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).usernameLabel,
                                    ),
                                    autofocus: true,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                  ),
                                  if (errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(S.of(context).cancelButton),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final newUsername = editController.text;
                                    if (username != newUsername &&
                                        usernameManager.usernames
                                            .contains(newUsername)) {
                                      setState(() {
                                        errorMessage =
                                            S.of(context).usernameExistsMessage;
                                      });
                                    } else {
                                      usernameManager.editUsername(
                                          username, newUsername);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Text(S.of(context).saveButton),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                              S.of(context).confirmDelete), // Localized string
                          content: Text(S
                              .of(context)
                              .confirmDeleteMessage), // Localized string
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(S
                                  .of(context)
                                  .cancelButton), // Localized string
                            ),
                            TextButton(
                              onPressed: () {
                                usernameManager.deleteUsername(username);
                                Navigator.of(context).pop();
                              },
                              child: Text(S
                                  .of(context)
                                  .deleteButton), // Localized string
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TextEditingController addController = TextEditingController();
          String? errorMessage;
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text(S.of(context).addUsername),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: addController,
                          decoration: InputDecoration(
                            labelText: S.of(context).usernameLabel,
                          ),
                          autofocus: true,
                          autocorrect: false,
                          enableSuggestions: false,
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(S.of(context).cancelButton),
                      ),
                      TextButton(
                        onPressed: () {
                          final newUsername = addController.text;
                          if (usernameManager.usernames.contains(newUsername)) {
                            setState(() {
                              errorMessage =
                                  S.of(context).usernameExistsMessage;
                            });
                          } else {
                            usernameManager.addUsername(newUsername);
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(S.of(context).addButton),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
