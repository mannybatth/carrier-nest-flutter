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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    'Phone Number: ${snapshot.data!.getString('phoneNumber')}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await DioClient().clearCookies();
                    await DioClient().clearPreferences();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DriverLoginPage()),
                    );
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No data found'));
        }
      },
    );
  }
}
