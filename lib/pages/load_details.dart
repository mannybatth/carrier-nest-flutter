import 'package:carrier_nest_flutter/helpers/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/helpers/helpers.dart';
import 'package:carrier_nest_flutter/helpers/load_utils.dart';
import 'package:carrier_nest_flutter/helpers/location_utils.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum MenuOptions { notInProgress, notDelivered }

class LoadDetailsPage extends StatefulWidget {
  final String loadId;

  const LoadDetailsPage({Key? key, required this.loadId}) : super(key: key);

  @override
  _LoadDetailsPageState createState() => _LoadDetailsPageState();
}

class _LoadDetailsPageState extends State<LoadDetailsPage> {
  bool _isLoading = true;
  late ExpandedLoad _load;
  late String _driverId;
  bool _dropOffDatePassed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDriverId();
    _fetchLoadDetails();
  }

  void _fetchDriverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverId = prefs.getString("driverId")!;
    });
  }

  void _fetchLoadDetails() async {
    try {
      ExpandedLoad load = await Loads.getLoadById(widget.loadId);
      setState(() {
        _load = load;
        _dropOffDatePassed = isDate24HrInThePast(load.receiver.date);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load details. Tap to retry.";
      });
    }
  }

  void _openAddressInMaps(String address) {
    MapUtils.openAddress(address);
  }

  void _getRouteDirections() {
    MapUtils.openRoute(_load);
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

  void _stopWork() {
    _updateLoadStatus(LoadStatus.CREATED);
  }

  void _beginWork() {
    _updateLoadStatus(LoadStatus.IN_PROGRESS);
  }

  void _completeWork() {
    _updateLoadStatus(LoadStatus.DELIVERED);
  }

  void _handleMenuOption(MenuOptions option) {
    switch (option) {
      case MenuOptions.notInProgress:
        _stopWork();
        break;
      case MenuOptions.notDelivered:
        _beginWork();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd', 'en_US').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading == false && _errorMessage == null
            ? _load.customer.name
            : ''),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildLoadDetails(),
    );
  }

  Widget _buildLoadDetails() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 64.0, top: 16.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBeginWorkButton(),
              _buildCompleteWorkButton(),
              _buildFilePickerButton(),
              const SizedBox(width: 18),
              _buildMenuButton(),
            ],
          ),
        ),
        _infoTile(label: 'Ref Num', value: _load.refNum),
        _infoTile(
            label: 'Shipper',
            value: _formatLoadStopAddress(stop: _load.shipper),
            tailingValue:
                "${_formatDate(_load.shipper.date)}\n${_load.shipper.time}",
            onTap: () {
              _showAddressOptionsDialog(_formatLoadStopAddress(
                  stop: _load.shipper, includeName: false));
            }),
        _expandableAdditionalInfoTile('Additional Info', _load.shipper),
        Divider(thickness: 1, color: Colors.grey[300]),
        ..._load.stops.asMap().entries.map((entry) {
          int index = entry.key;
          LoadStop stop = entry.value;
          return Column(
            children: [
              _infoTile(
                  label: 'Stop #${index + 1}',
                  value: _formatLoadStopAddress(stop: stop),
                  tailingValue: "${_formatDate(stop.date)}\n${stop.time}",
                  onTap: () {
                    _showAddressOptionsDialog(
                        _formatLoadStopAddress(stop: stop, includeName: false));
                  }),
              _expandableAdditionalInfoTile('Additional Info', stop),
              Divider(thickness: 1, color: Colors.grey[300]),
            ],
          );
        }).toList(),
        _infoTile(
            label: 'Receiver',
            value: _formatLoadStopAddress(stop: _load.receiver),
            tailingValue:
                "${_formatDate(_load.receiver.date)}\n${_load.receiver.time}",
            onTap: () {
              _showAddressOptionsDialog(_formatLoadStopAddress(
                  stop: _load.receiver, includeName: false));
            }),
        _expandableAdditionalInfoTile('Additional Info', _load.receiver),
        Divider(thickness: 1, color: Colors.grey[300]),
        _infoTile(
            label: 'Route Distance',
            value:
                '${metersToMiles(_load.routeDistance).toStringAsFixed(0)} miles'),
        _infoTile(
            label: 'Route Duration',
            value: secondsToReadable(_load.routeDuration)),
        ..._load.loadDocuments.map((doc) => _documentRow(doc)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: _buildDirectionsButton(),
        ),
        // Add more UI elements as needed
      ],
    );
  }

  Widget _expandableAdditionalInfoTile(String label, LoadStop stop) {
    // Additional details as a list of map objects
    List<Map<String, String>> additionalDetails = [];
    if (stop.poNumbers!.isNotEmpty) {
      additionalDetails.add({"label": "PO #'s", "value": stop.poNumbers!});
    }

    // Check the type of the LoadStop and set the label accordingly
    String pickUpLabel =
        stop.type == LoadStopType.RECEIVER ? "Del #'s" : "PU #'s";
    if (stop.pickUpNumbers!.isNotEmpty) {
      additionalDetails
          .add({"label": pickUpLabel, "value": stop.pickUpNumbers!});
    }

    if (stop.referenceNumbers!.isNotEmpty) {
      additionalDetails
          .add({"label": "Ref #'s", "value": stop.referenceNumbers!});
    }

    if (additionalDetails.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Set divider color to transparent
        ),
        child: ExpansionTile(
          title: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: additionalDetails.map((detail) {
            return _customListTile(detail, () {
              _showDetailOptionsDialog(detail['value']!);
            });
          }).toList(),
        ),
      );
    } else {
      return Container(); // Return an empty container if there are no additional details
    }
  }

  // New method to show the bottom sheet modal for details
  void _showDetailOptionsDialog(String detail) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy to Clipboard'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: detail)); // Copy to clipboard
                  Navigator.of(context).pop(); // Close the modal
                  const snackBar = SnackBar(
                    content: Text('Copied to Clipboard'),
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(snackBar); // Show confirmation
                },
              ),
              // Add more options if needed
            ],
          ),
        );
      },
    );
  }

  // Update _customListTile method
  Widget _customListTile(Map<String, String> detail, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${detail['label']!}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: detail['value']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLoadStopAddress(
      {required LoadStop stop, bool includeName = true}) {
    return "${includeName ? '${stop.name}\n' : ''}${stop.street}\n${stop.city}, ${stop.state} ${stop.zip}";
  }

  // Method to show the bottom sheet modal
  void _showAddressOptionsDialog(String address) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Address'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: address)); // Copy to clipboard
                  Navigator.of(context).pop(); // Close the modal
                  const snackBar = SnackBar(
                    content: Text('Copied to Clipboard'),
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(snackBar); // Show confirmation
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions),
                title: const Text('Get Directions'),
                onTap: () {
                  _openAddressInMaps(address); // Open address in maps
                  Navigator.of(context).pop(); // Close the modal
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Update _infoTile method
  Widget _infoTile(
      {required String label,
      required String value,
      String? tailingValue,
      VoidCallback? onTap}) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: tailingValue != null
          ? Text(tailingValue,
              textAlign: TextAlign.end, style: const TextStyle(fontSize: 14))
          : null,
      onTap: onTap ?? () {},
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
      onPressed: _getRouteDirections,
      icon: const Icon(Icons.map),
      label: const Text('Get Route Directions'),
    );
  }

  Widget _buildBeginWorkButton() {
    UILoadStatus currentStatus = loadStatus(_load);
    if (currentStatus == UILoadStatus.booked) {
      return Expanded(
        child: ElevatedButton(
          onPressed: _beginWork,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // This will stretch the button content
            children: [
              Text(''), // Empty text widget to create space
              Text('Begin Work'),
              Text(''), // Empty text widget to create space
            ],
          ),
        ),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Widget _buildCompleteWorkButton() {
    UILoadStatus currentStatus = loadStatus(_load);
    if (currentStatus == UILoadStatus.inProgress) {
      return Expanded(
        child: ElevatedButton(
          onPressed: _completeWork,
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Stretch the button content
            children: [
              Text(''), // Empty text widget to create space
              Text('Complete Work'),
              Text(''), // Empty text widget to create space
            ],
          ),
        ),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Widget _buildFilePickerButton() {
    UILoadStatus currentStatus = loadStatus(_load);
    if (currentStatus == UILoadStatus.delivered ||
        currentStatus == UILoadStatus.podReady) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showPickOptionsDialog(context),
          icon: const Icon(Icons.upload_file),
          label: const Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Stretch the button content
            children: [
              Text(''), // Empty text widget to create space
              Text('Upload Document'),
              Text(''), // Empty text widget to create space
            ],
          ),
        ),
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

  Widget _buildMenuButton() {
    UILoadStatus currentStatus = loadStatus(_load);
    if (!_dropOffDatePassed &&
        (currentStatus == UILoadStatus.inProgress ||
            currentStatus == UILoadStatus.delivered)) {
      return PopupMenuButton<MenuOptions>(
        onSelected: _handleMenuOption,
        itemBuilder: (BuildContext context) {
          List<PopupMenuEntry<MenuOptions>> menuItems = [];
          UILoadStatus currentStatus = loadStatus(_load);

          if (currentStatus == UILoadStatus.inProgress) {
            menuItems.add(
              const PopupMenuItem<MenuOptions>(
                value: MenuOptions.notInProgress,
                child: Text('Change to Not In Progress'),
              ),
            );
          }
          if (currentStatus == UILoadStatus.delivered) {
            menuItems.add(
              const PopupMenuItem<MenuOptions>(
                value: MenuOptions.notDelivered,
                child: Text('Change to Not Delivered'),
              ),
            );
          }

          return menuItems;
        },
      );
    } else {
      return Container(); // Return an empty container if the condition is not met
    }
  }

  Widget _buildErrorView() {
    return GestureDetector(
      onTap: _fetchLoadDetails,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
