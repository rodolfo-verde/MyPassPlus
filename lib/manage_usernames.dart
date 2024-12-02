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
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                              S.of(context).editUsername), // Localized string
                          content: TextField(
                            controller: editController,
                            decoration: InputDecoration(
                                labelText: S
                                    .of(context)
                                    .usernameLabel), // Localized string
                            autofocus: true,
                            onSubmitted: (value) {
                              usernameManager.editUsername(username, value);
                              Navigator.of(context).pop();
                            },
                          ),
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
                                usernameManager.editUsername(
                                    username, editController.text);
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                  S.of(context).saveButton), // Localized string
                            ),
                          ],
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
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(S.of(context).addUsername), // Localized string
                content: TextField(
                  controller: addController,
                  decoration: InputDecoration(
                      labelText:
                          S.of(context).usernameLabel), // Localized string
                  autofocus: true,
                  onSubmitted: (value) {
                    usernameManager.addUsername(value);
                    Navigator.of(context).pop();
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(S.of(context).cancelButton), // Localized string
                  ),
                  TextButton(
                    onPressed: () {
                      usernameManager.addUsername(addController.text);
                      Navigator.of(context).pop();
                    },
                    child: Text(S.of(context).addButton), // Localized string
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
