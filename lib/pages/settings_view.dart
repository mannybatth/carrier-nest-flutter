import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return ListView(
            children: <Widget>[
              ListTile(
                  title: const Text('Phone Number'),
                  subtitle: Text(snapshot.data!.getString('phoneNumber') ??
                      'Not available'),
                  onTap: () {}),
              ListTile(
                  title: const Text('Carrier Code'),
                  subtitle: Text(snapshot.data!.getString('carrierCode') ??
                      'Not available'),
                  onTap: () {}),
              const Divider(), // Added Divider here
              ListTile(
                leading: const Icon(Icons.logout), // Added Icon here
                title: const Text('Logout'),
                onTap: () async {
                  await DioClient().clearCookies();
                  await DioClient().clearPreferences();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DriverLoginPage()),
                  );
                },
              ),
            ],
          );
        } else {
          return const Center(child: Text('No data found'));
        }
      },
    );
  }
}
