import 'dart:io';

import 'package:carrier_nest_flutter/helpers/map_utils.dart';
import 'package:carrier_nest_flutter/rest/pod_upload.dart';
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
import 'package:url_launcher/url_launcher.dart';

enum MenuOptions { notInProgress, notDelivered }

class LoadDetailsPage extends StatefulWidget {
  final String loadId;

  const LoadDetailsPage({Key? key, required this.loadId}) : super(key: key);

  @override
  _LoadDetailsPageState createState() => _LoadDetailsPageState();
}

class _LoadDetailsPageState extends State<LoadDetailsPage> {
  bool _isLoading = true;
  bool _isStatusChangeLoading = false;
  bool _isUploadingPod = false;
  bool _isDeletingDocument = false;

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

  Future<void> _fetchLoadDetails() async {
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

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      _isUploadingPod = true;
    });

    var locationData = await LocationUtils.getDeviceLocation();
    var uploadResponse = await PodUpload.uploadFileToGCS(file);

    if (uploadResponse.uniqueFileName != null) {
      final simpleDoc = LoadDocument.fromJson({
        'fileKey': uploadResponse.uniqueFileName,
        'fileUrl': uploadResponse.gcsInputUri,
        'fileName': uploadResponse.originalFileName,
        'fileType': file.extension,
        'fileSize': file.size,
      });
      final longitude = locationData?.longitude;
      final latitude = locationData?.latitude;
      await Loads.addLoadDocumentToLoad(_load.id, simpleDoc,
          driverId: _driverId,
          isPod: true,
          longitude: longitude,
          latitude: latitude);

      await _fetchLoadDetails();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error uploading document: Upload response invalid'),
          backgroundColor: Colors.red));
    }

    setState(() {
      _isUploadingPod = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final PlatformFile file = PlatformFile(
        name: image.name,
        path: image.path,
        size: await File(image.path).length(),
        bytes: await File(image.path).readAsBytes(),
      );

      await _uploadFile(file);
    } else {
      // User canceled the picker
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      await _uploadFile(file);
    } else {
      // User canceled the picker
    }
  }

  Future<void> deleteLoadDocument(String id) async {
    setState(() {
      _isDeletingDocument = true; // Disable the list selection
    });
    try {
      await Loads.deleteLoadDocumentFromLoad(_load.id, id, query: {
        'driverId': _driverId,
        'isPod': true,
      });
      await _fetchLoadDetails();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting document: ${e.toString()}'),
          backgroundColor: Colors.red));
    }
    setState(() {
      _isDeletingDocument = false;
    });
  }

  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content:
                  const Text('Are you sure you want to delete this document?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context)
                      .pop(false), // Dismisses the dialog and returns false
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context)
                      .pop(true), // Dismisses the dialog and returns true
                ),
              ],
            );
          },
        ) ??
        false; // If dialog is dismissed by tapping outside, return false
  }

  Future<void> _updateLoadStatus(LoadStatus status) async {
    setState(() {
      _isStatusChangeLoading = true;
    });
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

      await _fetchLoadDetails();
    } catch (e) {
      // Handle error
      // For example: Show a dialog or a snackbar with the error message
    }
    setState(() {
      _isStatusChangeLoading = false;
    });
  }

  Future<void> _stopWork() {
    return _updateLoadStatus(LoadStatus.CREATED);
  }

  Future<void> _beginWork() {
    return _updateLoadStatus(LoadStatus.IN_PROGRESS);
  }

  Future<void> _completeWork() {
    return _updateLoadStatus(LoadStatus.DELIVERED);
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
    final firstRouteLeg = _load.route?.routeLegs.first;

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
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0), // Add vertical padding here
          child: Column(
            children: _generateDocumentListItems(),
          ),
        ),
        // ..._load.podDocuments.map((doc) => _documentRow(doc)),
        _infoTile(label: 'Ref Num', value: _load.refNum),

        // Displaying the first route leg locations
        if (firstRouteLeg != null)
          ...firstRouteLeg.locations.toList().asMap().entries.map((entry) {
            int index = entry.key;
            RouteLegLocation stopLocation = entry.value;
            return Column(
              children: [
                _infoTile(
                    label: 'Stop #${index + 1}',
                    value: _formatAddress(
                        stop: stopLocation.loadStop,
                        location: stopLocation.location),
                    tailingValue: (stopLocation.loadStop != null)
                        ? "${_formatDate(stopLocation.loadStop!.date)}\n${stopLocation.loadStop?.time}"
                        : "",
                    onTap: () {
                      _showAddressOptionsDialog(_formatAddress(
                          stop: stopLocation.loadStop,
                          location: stopLocation.location,
                          includeName: false));
                    }),
                if (stopLocation.loadStop != null)
                  _expandableAdditionalInfoTile(
                      'Additional Info', stopLocation.loadStop!),
                Divider(thickness: 1, color: Colors.grey[300]),
              ],
            );
          }).toList(),

        Divider(thickness: 1, color: Colors.grey[300]),
        _infoTile(
            label: 'Route Distance',
            value: firstRouteLeg?.routeLegDistance != null
                ? '${metersToMiles(firstRouteLeg!.routeLegDistance).toStringAsFixed(0)} miles'
                : '0'),
        _infoTile(
            label: 'Route Duration',
            value: firstRouteLeg?.routeLegDistance != null
                ? secondsToReadable(firstRouteLeg!.routeLegDistance)
                : '0'),
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

  String _formatAddress(
      {LoadStop? stop, Location? location, bool includeName = true}) {
    if (stop != null) {
      return "${includeName ? '${stop.name}\n' : ''}${stop.street}\n${stop.city}, ${stop.state} ${stop.zip}";
    } else if (location != null) {
      return "${includeName ? '${location.name}\n' : ''}${location.street}\n${location.city}, ${location.state} ${location.zip}";
    } else {
      return '';
    }
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

  List<Widget> _generateDocumentListItems() {
    return List.generate(_load.podDocuments.length, (int index) {
      bool isFirst = index == 0;
      bool isLast = index == _load.podDocuments.length - 1;
      bool isOnly = _load.podDocuments.length == 1;

      BorderSide borderSide = BorderSide(color: Colors.grey[300]!, width: 1);
      BorderSide zeroBorderSide =
          BorderSide(color: Colors.grey[300]!, width: 0);

      BorderRadiusGeometry borderRadius;
      if (isOnly) {
        borderRadius = BorderRadius.circular(8.0);
      } else if (isFirst) {
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        );
      } else if (isLast) {
        borderRadius = const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        );
      } else {
        borderRadius = BorderRadius.circular(0);
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
        decoration: BoxDecoration(
          border: Border(
            left: borderSide,
            right: borderSide,
            top: borderSide,
            bottom: isLast ? borderSide : zeroBorderSide,
          ),
          borderRadius: borderRadius,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12.0, right: 8.0),
          leading: const Icon(Icons.attach_file, color: Colors.grey),
          title: Text(
            _load.podDocuments[index].fileName,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeletingDocument
                ? null
                : () async {
                    // Show confirmation dialog before deleting
                    bool confirmDelete =
                        await showDeleteConfirmationDialog(context);
                    if (confirmDelete) {
                      deleteLoadDocument(_load.podDocuments[index].id!);
                    }
                  },
          ),
          onTap: _isDeletingDocument
              ? null
              : () async {
                  // Implement logic to open document
                  final url = _load.podDocuments[index].fileUrl;
                  try {
                    await launchUrl(Uri.parse(url));
                  } catch (e) {
                    final snackBar =
                        SnackBar(content: Text('Failed to open document: $e'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
        ),
      );
    });
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
        onPressed: _isStatusChangeLoading ? null : _beginWork,
        child: _isStatusChangeLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : const Text('Begin Work'),
      ));
    }
    return Container();
  }

  Widget _buildCompleteWorkButton() {
    UILoadStatus currentStatus = loadStatus(_load);
    if (currentStatus == UILoadStatus.inProgress) {
      return Expanded(
        child: ElevatedButton(
          onPressed: _isStatusChangeLoading ? null : _completeWork,
          child: _isStatusChangeLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text(
                  'Complete Work'), // Empty text widget to create space
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
          onPressed: _isStatusChangeLoading || _isUploadingPod
              ? null
              : () {
                  _showPickOptionsDialog(context);
                },
          icon: _isStatusChangeLoading || _isUploadingPod
              ? const SizedBox.shrink() // This will effectively hide the icon
              : const Icon(Icons.upload_file),
          label: _isStatusChangeLoading || _isUploadingPod
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text('Upload Document'),
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
