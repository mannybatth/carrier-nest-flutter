import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/models.dart';

class LoadDetailsPage extends StatefulWidget {
  final String loadId;

  const LoadDetailsPage({Key? key, required this.loadId}) : super(key: key);

  @override
  _LoadDetailsPageState createState() => _LoadDetailsPageState();
}

class _LoadDetailsPageState extends State<LoadDetailsPage> {
  late Future<ExpandedLoad> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = Loads.getLoadById(widget.loadId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Details'),
      ),
      body: FutureBuilder<ExpandedLoad>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            ExpandedLoad load = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ref Num: ${load.refNum}'),
                Text('Customer: ${load.customer.name}'),
                Text('Shipper: ${load.shipper.name}'),
                Text('Receiver: ${load.receiver.name}'),
              ],
            );
          }
        },
      ),
    );
  }
}
