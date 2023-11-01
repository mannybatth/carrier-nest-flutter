import 'package:carrier_nest_flutter/helpers/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carrier_nest_flutter/helpers/helpers.dart';
import 'package:carrier_nest_flutter/helpers/load_utils.dart';
import 'package:carrier_nest_flutter/helpers/location_utils.dart';

class LoadDetailsPage extends StatefulWidget {
  final String loadId;

  const LoadDetailsPage({Key? key, required this.loadId}) : super(key: key);

  @override
  _LoadDetailsPageState createState() => _LoadDetailsPageState();
}

class _LoadDetailsPageState extends State<LoadDetailsPage> {
  bool _isLoading = true;
  ExpandedLoad? _load;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _fetchDriverId();
    _fetchLoadDetails();
  }

  void _fetchDriverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverId = prefs.getString("driverId");
    });
  }

  void _fetchLoadDetails() async {
    try {
      ExpandedLoad load = await Loads.getLoadById(widget.loadId);
      setState(() {
        _load = load;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAddressInMaps(String address) {
    MapUtils.openAddress(address);
  }

  void _openRouteInGoogleMaps() {
    MapUtils.openRouteInGoogleMaps(_load!);
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // Image selected
      // You can access the image file using image.path
    } else {
      // User canceled the picker
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // File selected
      PlatformFile file = result.files.first;
      // You can access the file's path using file.path
    } else {
      // User canceled the picker
    }
  }

  Future<void> _updateLoadStatus(LoadStatus status) async {
    if (_load == null || _driverId == null) return;

    try {
      var locationData = await LocationUtils.getDeviceLocation();

      if (locationData != null) {
        await Loads.updateLoadStatus(
          loadId: widget.loadId,
          status: status,
          driverId: _driverId,
          longitude: locationData.longitude,
          latitude: locationData.latitude,
        );
      } else {
        await Loads.updateLoadStatus(
          loadId: widget.loadId,
          status: status,
          driverId: _driverId,
        );
      }

      _fetchLoadDetails();
    } catch (e) {
      // Handle error
      // For example: Show a dialog or a snackbar with the error message
    }
  }

  void _beginWork() {
    _updateLoadStatus(LoadStatus.IN_PROGRESS);
  }

  void _completeWork() {
    _updateLoadStatus(LoadStatus.DELIVERED);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_load?.customer.name ?? ''),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _load != null
              ? _buildLoadDetails()
              : const Center(child: Text('No Load Found')),
    );
  }

  Widget _buildLoadDetails() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _infoRow('Ref Num', _load!.refNum),
        // const Divider(color: Colors.grey),
        _infoRow('Shipper', _load!.shipper.name),
        _infoRow('Receiver', _load!.receiver.name),
        _infoRow('Route Distance',
            '${metersToMiles(_load!.routeDistance).toStringAsFixed(0)} miles'),
        _infoRow('Route Duration', secondsToReadable(_load!.routeDuration)),
        ..._load!.loadDocuments.map((doc) => _documentRow(doc)),
        _buildDirectionsButton(),
        _buildBeginWorkButton(),
        _buildCompleteWorkButton(),
        _buildFilePickerButton(),
        // Add more UI elements as needed
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _documentRow(LoadDocument doc) {
    return ListTile(
      title: Text(doc.fileName),
      trailing: _driverId == doc.driverId
          ? IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Implement logic to delete document
              },
            )
          : null,
      onTap: () {
        // Implement logic to open document
      },
    );
  }

  Widget _buildDirectionsButton() {
    return ElevatedButton.icon(
      onPressed: _openRouteInGoogleMaps,
      icon: const Icon(Icons.map),
      label: const Text('Get Directions'),
    );
  }

  Widget _buildBeginWorkButton() {
    UILoadStatus currentStatus = loadStatus(_load!);
    if (currentStatus == UILoadStatus.booked) {
      return ElevatedButton(
        onPressed: _beginWork,
        child: const Text('Begin Work'),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Widget _buildCompleteWorkButton() {
    UILoadStatus currentStatus = loadStatus(_load!);
    if (currentStatus == UILoadStatus.inProgress) {
      return ElevatedButton(
        onPressed: _completeWork,
        child: const Text('Complete Work'),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Widget _buildFilePickerButton() {
    UILoadStatus currentStatus = loadStatus(_load!);
    if (currentStatus == UILoadStatus.delivered ||
        currentStatus == UILoadStatus.podReady) {
      return ElevatedButton.icon(
        onPressed: () => _showPickOptionsDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Future<void> _showPickOptionsDialog(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('File'),
                onTap: () {
                  _pickFile();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
