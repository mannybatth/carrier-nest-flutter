import 'dart:io';

import 'package:carrier_nest_flutter/helpers/map_utils.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:carrier_nest_flutter/rest/pod_upload.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
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

class AssignmentDetailsPage extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailsPage({Key? key, required this.assignmentId}) : super(key: key);

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  bool _isLoading = true;
  bool _isStatusChangeLoading = false;
  bool _isUploadingPod = false;
  bool _isDeletingDocument = false;

  late ExpandedLoad? _load;
  late RouteLeg? _routeLeg;
  late String _driverId;
  bool _dropOffDatePassed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDriverId();
    _fetchAssignmentDetails();
  }

  void _fetchDriverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverId = prefs.getString("driverId")!;
    });
  }

  Future<void> _fetchAssignmentDetails() async {
    try {
      DriverAssignment assignment = await Assignments.getAssignmentById(assignmentId: widget.assignmentId);

      ExpandedLoad load = assignment.load!;
      RouteLeg routeLeg = assignment.routeLeg!;

      setState(() {
        _load = load;
        _routeLeg = routeLeg;
        _dropOffDatePassed = false; //isDate24HrInThePast(load.receiver.date);
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
    if (_routeLeg != null) {
      MapUtils.openRoute(_routeLeg!);
    } else if (_load != null) {
      MapUtils.openRouteFromLoad(_load!);
    }
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
      await Loads.addLoadDocumentToLoad(_load!.id, simpleDoc, driverId: _driverId, isPod: true, longitude: longitude, latitude: latitude);

      await _fetchAssignmentDetails();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading document: Upload response invalid'), backgroundColor: Colors.red));
    }

    setState(() {
      _isUploadingPod = false;
    });
  }

  /* Future<void> _scanDocument() async {
    //by default way they fetch pdf for android and png for iOS
    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScannedDocumentAsPdf() ?? 'Unknown platform documents';
      print(scannedDocuments.toString());
      await _uploadFile(scannedDocuments);
    } on PlatformException {
      scannedDocuments = 'Failed to get scanned documents.';
    }
  } */

  Future<void> _scanDocument() async {
    try {
      final String? scannedPath = await FlutterDocScanner().getScannedDocumentAsPdf();

      if (scannedPath != null) {
        final File file = File(scannedPath);

        final PlatformFile platformFile = PlatformFile(
          name: scannedPath.split('/').last,
          path: scannedPath,
          size: await file.length(),
          bytes: await file.readAsBytes(),
        );

        await _uploadFile(platformFile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document scanned'), backgroundColor: Colors.orange),
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan document'), backgroundColor: Colors.red),
      );
    }
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
      await Loads.deleteLoadDocumentFromLoad(_load!.id, id, query: {
        'driverId': _driverId,
        'isPod': true,
      });
      await _fetchAssignmentDetails();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting document: ${e.toString()}'), backgroundColor: Colors.red));
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
              content: const Text('Are you sure you want to delete this document?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false), // Dismisses the dialog and returns false
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true), // Dismisses the dialog and returns true
                ),
              ],
            );
          },
        ) ??
        false; // If dialog is dismissed by tapping outside, return false
  }

  Future<void> _updateRouteLegStatus(RouteLegStatus status) async {
    setState(() {
      _isStatusChangeLoading = true;
    });
    try {
      var locationData = await LocationUtils.getDeviceLocation();

      if (locationData != null) {
        if (status == RouteLegStatus.IN_PROGRESS) {
          await Assignments.updateRouteLegStatus(
            routeLegId: _routeLeg!.id,
            routeLegStatus: status,
            startLatitude: locationData.latitude,
            startLongitude: locationData.longitude,
          );
        } else if (status == RouteLegStatus.COMPLETED) {
          await Assignments.updateRouteLegStatus(
            routeLegId: _routeLeg!.id,
            routeLegStatus: status,
            endLatitude: locationData.latitude,
            endLongitude: locationData.longitude,
          );
        } else {
          await Assignments.updateRouteLegStatus(
            routeLegId: _routeLeg!.id,
            routeLegStatus: status,
            activityLatitude: locationData.latitude,
            activityLongitude: locationData.longitude,
          );
        }
      } else {
        await Assignments.updateRouteLegStatus(
          routeLegId: _routeLeg!.id,
          routeLegStatus: status,
        );
      }

      await _fetchAssignmentDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
    setState(() {
      _isStatusChangeLoading = false;
    });
  }

  Future<void> _stopWork() {
    return _updateRouteLegStatus(RouteLegStatus.ASSIGNED);
  }

  Future<void> _beginWork() {
    return _updateRouteLegStatus(RouteLegStatus.IN_PROGRESS);
  }

  Future<void> _completeWork() {
    return _updateRouteLegStatus(RouteLegStatus.COMPLETED);
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

  // convert route leg status to user friendly string
  String _formatRouteLegStatus(RouteLegStatus status) {
    switch (status) {
      case RouteLegStatus.ASSIGNED:
        return 'Assigned';
      case RouteLegStatus.IN_PROGRESS:
        return 'In Progress';
      case RouteLegStatus.COMPLETED:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading == false && _errorMessage == null ? 'Assignment Details' : ''),
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
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 4),
                blurRadius: 12.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                ),
                child: _buildDirectionsButton(),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBeginWorkButton(),
                    _buildCompleteWorkButton(),
                    _buildFilePickerButton(),
                    _buildMenuButton(),
                  ],
                ),
              ),
              _load != null && _load!.podDocuments.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16), // Add vertical padding here
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: _generateDocumentListItems(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),

        _routeLeg?.status == RouteLegStatus.COMPLETED
            ? Container(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                margin: const EdgeInsets.only(left: 16.0, right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.green[500],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Completed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                margin: const EdgeInsets.only(left: 16.0, right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        _routeLeg?.status != null ? _formatRouteLegStatus(_routeLeg!.status) : 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
        // ..._load.podDocuments.map((doc) => _documentRow(doc)),
        _infoTile(label: 'Order#', value: _load!.refNum),
        _infoTile(
            label: 'Scheduled For',
            value:
                '${_formatDate(_routeLeg!.scheduledDate!)} at ${DateFormat("hh:mm a").format(DateFormat("HH:mm").parse(_routeLeg!.scheduledTime))} '),
        // Write code to extract the notes from the load
        // _load!.route.routeLegs[0].driverInstructions is the notes location
        // _infoTile(label: 'Notes', value: _load!.route.routeLegs[0].driverInstructions),

        _routeLeg?.driverInstructions != ''
            ? _infoTile(label: 'Notes', value: _routeLeg?.driverInstructions ?? 'No notes available')
            : Container(),

        // Displaying the first route leg locations
        if (_routeLeg != null)
          ..._routeLeg!.locations.toList().asMap().entries.map((entry) {
            int index = entry.key;
            RouteLegLocation stopLocation = entry.value;
            return Column(
              children: [
                _infoTile(
                    label: 'Stop #${index + 1}',
                    value: _formatAddress(stop: stopLocation.loadStop, location: stopLocation.location),
                    tailingValue: (stopLocation.loadStop != null)
                        ? "${_formatDate(stopLocation.loadStop!.date)}\n${stopLocation.loadStop?.time}"
                        : "",
                    onTap: () {
                      _showAddressOptionsDialog(
                          _formatAddress(stop: stopLocation.loadStop, location: stopLocation.location, includeName: false));
                    }),
                if (stopLocation.loadStop != null) _expandableAdditionalInfoTile('Additional Info', stopLocation.loadStop!),
                Divider(thickness: 1, color: Colors.grey[300]),
              ],
            );
          }).toList(),
        _buildDriverNames(_routeLeg!.driverAssignments),
        _infoTile(
            label: 'Route Distance',
            value: _routeLeg?.distanceMiles != null ? '${_routeLeg!.distanceMiles.toStringAsFixed(2)} miles' : '0'),
        _infoTile(label: 'Route Duration', value: _routeLeg?.durationHours != null ? hoursToReadable(_routeLeg!.durationHours) : '0'),
        const SizedBox(
          height: 16,
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
    String pickUpLabel = stop.type == LoadStopType.RECEIVER ? "Del #'s" : "PU #'s";
    if (stop.pickUpNumbers!.isNotEmpty) {
      additionalDetails.add({"label": pickUpLabel, "value": stop.pickUpNumbers!});
    }

    if (stop.referenceNumbers!.isNotEmpty) {
      additionalDetails.add({"label": "Ref #'s", "value": stop.referenceNumbers!});
    }

    if (additionalDetails.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Set divider color to transparent
        ),
        child: ExpansionTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  Clipboard.setData(ClipboardData(text: detail)); // Copy to clipboard
                  Navigator.of(context).pop(); // Close the modal
                  const snackBar = SnackBar(
                    content: Text('Copied to Clipboard'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar); // Show confirmation
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

  String _formatAddress({LoadStop? stop, Location? location, bool includeName = true}) {
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
                  Clipboard.setData(ClipboardData(text: address)); // Copy to clipboard
                  Navigator.of(context).pop(); // Close the modal
                  const snackBar = SnackBar(
                    content: Text('Copied to Clipboard'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar); // Show confirmation
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
  Widget _infoTile({required String label, required String value, String? tailingValue, VoidCallback? onTap}) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: tailingValue != null ? Text(tailingValue, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14)) : null,
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDriverNames(List<DriverAssignment> driverAssignments) {
    String driverNames = driverAssignments.map((assignment) => assignment.driver.name).join(', ');

    return _infoTile(
      label: 'Assigned Drivers',
      value: driverNames,
    );
  }

  List<Widget> _generateDocumentListItems() {
    return List.generate(_load!.podDocuments.length, (int index) {
      bool isFirst = index == 0;
      bool isLast = index == _load!.podDocuments.length - 1;
      bool isOnly = _load!.podDocuments.length == 1;

      bool hasInvoiceId = _load!.invoice?.id != null;

      BorderSide borderSide = BorderSide(color: Colors.grey[300]!, width: 1);
      BorderSide zeroBorderSide = BorderSide(color: Colors.grey[300]!, width: 0);

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
        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(
            left: borderSide,
            right: borderSide,
            top: borderSide,
            bottom: borderSide,
          ),
          borderRadius: borderRadius,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 8.0, right: 2.0, top: 0.0, bottom: 0.0),
          leading: const Icon(Icons.attach_file, color: Colors.grey),
          title: Text(
            _load!.podDocuments[index].fileName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          trailing: !hasInvoiceId
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _isDeletingDocument
                      ? null
                      : () async {
                          // Show confirmation dialog before deleting
                          bool confirmDelete = await showDeleteConfirmationDialog(context);
                          if (confirmDelete) {
                            deleteLoadDocument(_load!.podDocuments[index].id!);
                          }
                        },
                )
              : null,
          onTap: _isDeletingDocument
              ? null
              : () async {
                  // Implement logic to open document
                  final url = _load!.podDocuments[index].fileUrl;
                  try {
                    await launchUrl(Uri.parse(url));
                  } catch (e) {
                    final snackBar = SnackBar(content: Text('Failed to open document: $e'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
        ),
      );
    });
  }

  Widget _buildDirectionsButton() {
    return ElevatedButton.icon(
      iconAlignment: IconAlignment.start,
      onPressed: _getRouteDirections,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      icon: const Icon(Icons.map, color: Colors.white),
      label: const Text(
        'Get Route Directions',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBeginWorkButton() {
    // UILoadStatus currentStatus = loadStatus(_load);
    RouteLegStatus status = _routeLeg!.status;
    if (status == RouteLegStatus.ASSIGNED) {
      return Expanded(
          child: ElevatedButton(
        onPressed: _isStatusChangeLoading ? null : _beginWork,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        child: _isStatusChangeLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : const Text(
                'Begin Work',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
      ));
    }
    return Container();
  }

  Widget _buildCompleteWorkButton() {
    // UILoadStatus currentStatus = loadStatus(_load);
    RouteLegStatus status = _routeLeg!.status;
    if (status == RouteLegStatus.IN_PROGRESS) {
      return Expanded(
        child: ElevatedButton(
          onPressed: _isStatusChangeLoading ? null : _completeWork,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          child: _isStatusChangeLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text('Complete Work',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), // Empty text widget to create space
        ),
      );
    }
    return Container(); // Return an empty container if the condition is not met
  }

  Widget _buildFilePickerButton() {
    UILoadStatus currentStatus = loadStatus(_load!);
    RouteLegStatus status = _routeLeg!.status;

    // checi if invoice id is not null
    bool hasInvoiceId = _load!.invoice?.id != null;

    if (!hasInvoiceId &&
        status == RouteLegStatus.COMPLETED &&
        (currentStatus == UILoadStatus.inProgress || currentStatus == UILoadStatus.delivered || currentStatus == UILoadStatus.podReady)) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: _isStatusChangeLoading || _isUploadingPod
              ? null
              : () {
                  _showPickOptionsDialog(context);
                },
          icon: _isStatusChangeLoading || _isUploadingPod
              ? const SizedBox.shrink() // This will effectively hide the icon
              : const Icon(Icons.upload_file, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          label: _isStatusChangeLoading || _isUploadingPod
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text('Upload Document', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
                  leading: const Icon(Icons.scanner),
                  title: const Text('Scan Document'),
                  onTap: () {
                    _scanDocument();
                    Navigator.of(context).pop();
                  }),
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
    // UILoadStatus currentStatus = loadStatus(_load);
    // check if invoice id is not null
    bool hasInvoiceId = _load!.invoice?.id != null;
    // Check if endedat is 24 hours in the past
    bool checkedInDate24Past = isDate24HrInThePast(_routeLeg?.endedAt ?? DateTime.now());

    if (hasInvoiceId || checkedInDate24Past) {
      return Container(); // Return an empty container if the condition is not met
    }

    RouteLegStatus status = _routeLeg!.status;
    if (!_dropOffDatePassed &&
        _load != null &&
        _load!.podDocuments.isEmpty &&
        (status == RouteLegStatus.IN_PROGRESS || status == RouteLegStatus.COMPLETED)) {
      return PopupMenuButton<MenuOptions>(
        onSelected: _handleMenuOption,
        itemBuilder: (BuildContext context) {
          List<PopupMenuEntry<MenuOptions>> menuItems = [];
          // UILoadStatus currentStatus = loadStatus(_load);
          RouteLegStatus status = _routeLeg!.status;

          if (status == RouteLegStatus.IN_PROGRESS) {
            menuItems.add(
              const PopupMenuItem<MenuOptions>(
                value: MenuOptions.notInProgress,
                child: Text('Change to Not In Progress'),
              ),
            );
          }
          if (status == RouteLegStatus.COMPLETED) {
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
    // UILoadStatus currentStatus = loadStatus(_load);
    // if (!_dropOffDatePassed &&
    //     (currentStatus == UILoadStatus.inProgress ||
    //         currentStatus == UILoadStatus.delivered)) {
    //   return PopupMenuButton<MenuOptions>(
    //     onSelected: _handleMenuOption,
    //     itemBuilder: (BuildContext context) {
    //       List<PopupMenuEntry<MenuOptions>> menuItems = [];
    //       UILoadStatus currentStatus = loadStatus(_load);

    //       if (currentStatus == UILoadStatus.inProgress) {
    //         menuItems.add(
    //           const PopupMenuItem<MenuOptions>(
    //             value: MenuOptions.notInProgress,
    //             child: Text('Change to Not In Progress'),
    //           ),
    //         );
    //       }
    //       if (currentStatus == UILoadStatus.delivered) {
    //         menuItems.add(
    //           const PopupMenuItem<MenuOptions>(
    //             value: MenuOptions.notDelivered,
    //             child: Text('Change to Not Delivered'),
    //           ),
    //         );
    //       }

    //       return menuItems;
    //     },
    //   );
    // } else {
    //   return Container(); // Return an empty container if the condition is not met
    // }
  }

  Widget _buildErrorView() {
    return GestureDetector(
      onTap: _fetchAssignmentDetails,
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
