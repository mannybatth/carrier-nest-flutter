import 'dart:io';
import 'dart:async';

import 'package:carrier_nest_flutter/helpers/map_utils.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:carrier_nest_flutter/rest/pod_upload.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/helpers/helpers.dart';
import 'package:carrier_nest_flutter/helpers/location_utils.dart';
import 'dart:math';
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
  bool _isRefreshing = false;
  bool _isStatusChangeLoading = false;
  bool _isUploadingDocument = false; // For bottom navigation loading state only

  // Track individual documents being deleted
  Set<String> _deletingDocuments = {};

  ExpandedLoad? _load;
  RouteLeg? _routeLeg;
  late String _driverId;
  String? _errorMessage;
  String _currentDocumentType = 'Document'; // Track current document type being uploaded

  // Track copied addresses for visual feedback
  Map<String, bool> _copiedAddresses = {};

  // Get platform-specific font family
  String get _fontFamily {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'SF Pro Display';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Roboto';
    }
    return 'system-ui';
  }

  @override
  void initState() {
    super.initState();
    _fetchDriverId();
    _fetchAssignmentDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchDriverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverId = prefs.getString("driverId")!;
    });
  }

  Future<void> _fetchAssignmentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DriverAssignment assignment = await Assignments.getAssignmentById(assignmentId: widget.assignmentId);

      ExpandedLoad load = assignment.load!;
      RouteLeg routeLeg = assignment.routeLeg!;

      setState(() {
        _load = load;
        _routeLeg = routeLeg;
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

  Future<void> _refreshAssignmentDataSilently() async {
    try {
      DriverAssignment assignment = await Assignments.getAssignmentById(assignmentId: widget.assignmentId);

      ExpandedLoad load = assignment.load!;
      RouteLeg routeLeg = assignment.routeLeg!;

      setState(() {
        _load = load;
        _routeLeg = routeLeg;
        _errorMessage = null;
      });
    } catch (e) {
      // Don't update loading state on error during silent refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh assignment data'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _refreshAssignmentDetails() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      DriverAssignment assignment = await Assignments.getAssignmentById(assignmentId: widget.assignmentId);

      ExpandedLoad load = assignment.load!;
      RouteLeg routeLeg = assignment.routeLeg!;

      setState(() {
        _load = load;
        _routeLeg = routeLeg;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = "Failed to load details. Tap to retry.";
      });
    }
  }

  void _openRouteInMaps() {
    if (_routeLeg != null) {
      MapUtils.openRoute(_routeLeg!);
    } else if (_load != null) {
      MapUtils.openRouteFromLoad(_load!);
    }
  }

  Future<void> _showPickOptionsDialog(BuildContext context, {String documentType = 'Document'}) async {
    // Store the document type for use in upload methods
    _currentDocumentType = documentType;

    // Customize title, description, and scan text based on document type
    String title;
    String description;
    String scanText;

    switch (documentType.toUpperCase()) {
      case 'BOL':
        title = 'Add BOL Document';
        description = 'Choose how you would like to add your Bill of Lading';
        scanText = 'Scan BOL';
        break;
      case 'POD':
        title = 'Add POD Document';
        description = 'Choose how you would like to add your Proof of Delivery';
        scanText = 'Scan POD';
        break;
      default:
        title = 'Add Document';
        description = 'Choose how you would like to add your document';
        scanText = 'Scan Document';
        break;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
          message: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              fontFamily: _fontFamily,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _scanDocument();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text_viewfinder,
                    size: 20,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    scanText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _fontFamily,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo_on_rectangle,
                    size: 20,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Photo Library',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _fontFamily,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.camera_fill,
                    size: 20,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _fontFamily,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickFile();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.folder_fill,
                    size: 20,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Browse Files',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _fontFamily,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: _fontFamily,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      scanText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: _fontFamily,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      documentType.toUpperCase() == 'DOCUMENT'
                          ? 'Use camera to scan documents'
                          : 'Use camera to scan ${documentType.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: _fontFamily,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _scanDocument();
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: Colors.green[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Photo Library',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: _fontFamily,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Choose from existing photos',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: _fontFamily,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: _fontFamily,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Take a new photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: _fontFamily,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: Colors.purple[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Browse Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: _fontFamily,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Choose from device storage',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: _fontFamily,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickFile();
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _uploadFile(PlatformFile file, {bool manageState = true}) async {
    if (manageState) {
      setState(() {
        _isUploadingDocument = true;
      });
    }

    try {
      var locationData = await LocationUtils.getDeviceLocation();

      // Generate new filename based on document type
      final newFileName = _generateFileName(_currentDocumentType, file.name);

      // Create a new PlatformFile with the updated name
      final updatedFile = PlatformFile(
        name: newFileName,
        path: file.path,
        size: file.size,
        bytes: file.bytes,
      );

      var uploadResponse = await PodUpload.uploadFileToGCS(updatedFile);

      if (uploadResponse.uniqueFileName != null) {
        final simpleDoc = LoadDocument.fromJson({
          'fileKey': uploadResponse.uniqueFileName,
          'fileUrl': uploadResponse.gcsInputUri,
          'fileName': newFileName, // Use the new filename
          'fileType': file.extension,
          'fileSize': file.size,
        });
        final longitude = locationData?.longitude;
        final latitude = locationData?.latitude;

        // Determine the appropriate flag based on document type
        bool? isPod;
        bool? isBol;

        if (_currentDocumentType.toLowerCase() == 'pod') {
          isPod = true;
        } else if (_currentDocumentType.toLowerCase() == 'bol') {
          isBol = true;
        }
        // For other document types, neither isPod nor isBol is set

        await Loads.addLoadDocumentToLoad(_load!.id, simpleDoc,
            driverId: _driverId, isPod: isPod, isBol: isBol, longitude: longitude, latitude: latitude);

        await _refreshAssignmentDataSilently();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error uploading document: Upload response invalid'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading document: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      // Only clear the uploading state if this method is managing it
      if (manageState) {
        setState(() {
          _isUploadingDocument = false;
        });
      }
    }
  }

  /// Format driver name by removing spaces and converting to lowercase
  String _formatDriverName(String driverName) {
    return driverName.replaceAll(' ', '').toLowerCase();
  }

  /// Get current driver name from driver assignments
  String _getCurrentDriverName() {
    if (_routeLeg?.driverAssignments.isNotEmpty == true) {
      // Find the driver assignment that matches the current driver ID
      final assignment = _routeLeg!.driverAssignments.firstWhere(
        (assignment) => assignment.driver.id == _driverId,
        orElse: () => _routeLeg!.driverAssignments.first,
      );
      return assignment.driver.name;
    }
    return 'Unknown';
  }

  /// Generate filename with format: TYPE-DriverName-MM-DD-YY-timeinmilliseconds.extension
  String _generateFileName(String documentType, String originalFileName) {
    final driverName = _getCurrentDriverName();
    final formattedDriverName = _formatDriverName(driverName);
    final now = DateTime.now();
    final dateString = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year.toString().substring(2)}';
    final timeInMilliseconds = now.millisecondsSinceEpoch;

    // Get file extension
    final extension = originalFileName.split('.').last;

    // Create new filename
    return '$documentType-$formattedDriverName-$dateString-$timeInMilliseconds.$extension';
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
    // Set uploading state immediately
    setState(() {
      _isUploadingDocument = true;
    });

    try {
      // Call the FlutterDocScanner to scan and get PDF
      final String? scannedPath = await FlutterDocScanner().getScannedDocumentAsPdf();

      if (scannedPath != null && scannedPath.isNotEmpty) {
        final File file = File(scannedPath);

        // Check if file exists and is valid
        if (await file.exists()) {
          final fileSize = await file.length();

          if (fileSize > 0) {
            // Generate proper filename based on document type with PDF extension
            final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            final driverName = _getCurrentDriverName();
            final formattedDriverName = _formatDriverName(driverName);
            final now = DateTime.now();
            final dateString =
                '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.year.toString().substring(2)}';

            // Ensure PDF extension for scanned documents
            final scannedFileName = '${_currentDocumentType}-$formattedDriverName-$dateString-$timestamp.pdf';

            final PlatformFile platformFile = PlatformFile(
              name: scannedFileName,
              path: scannedPath,
              size: fileSize,
              bytes: await file.readAsBytes(),
            );

            // Upload the scanned document
            await _uploadFile(platformFile, manageState: false);

            // Success message is handled in _uploadFile method
            print('Successfully scanned and uploaded: ${_currentDocumentType} document');
          } else {
            throw Exception('Scanned file is empty');
          }
        } else {
          throw Exception('Scanned file does not exist at path: $scannedPath');
        }
      } else {
        // User cancelled scanning or no document was scanned
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Document scanning was cancelled',
                style: TextStyle(fontFamily: _fontFamily),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      print('PlatformException during document scanning: ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to scan document: ${e.message ?? 'Unknown error'}',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      print('Error during document scanning: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error scanning document: $e',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      // Always clear the uploading state, regardless of success or failure
      setState(() {
        _isUploadingDocument = false;
      });
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
    // Find the document to check permissions
    LoadDocument? docToDelete;

    // Search for the document in all document lists
    for (var doc in _load!.loadDocuments) {
      if (doc.id == id) {
        docToDelete = doc;
        break;
      }
    }
    for (var doc in _load!.podDocuments) {
      if (doc.id == id) {
        docToDelete = doc;
        break;
      }
    }
    for (var doc in _load!.bolDocuments) {
      if (doc.id == id) {
        docToDelete = doc;
        break;
      }
    }

    // Check if user can delete this document
    if (docToDelete == null || !_canDeleteDocument(docToDelete)) {
      _showSnackBar('You can only delete documents you uploaded', isError: true);
      return;
    }

    setState(() {
      _deletingDocuments.add(id); // Add document to deleting set
    });
    try {
      await Loads.deleteLoadDocumentFromLoad(_load!.id, id, query: {
        'driverId': _driverId,
        'isPod': true,
      });
      await _refreshAssignmentDataSilently();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting document: ${e.toString()}'), backgroundColor: Colors.red));
    }
    setState(() {
      _deletingDocuments.remove(id); // Remove document from deleting set
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
    // Check if status changes are allowed
    if (!_canChangeStatus()) {
      _showSnackBar('Cannot change status: Assignment has been invoiced and completed', isError: true);
      return;
    }

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

      // Update local state instead of fetching everything again
      setState(() {
        _routeLeg = RouteLeg(
          id: _routeLeg!.id,
          scheduledDate: _routeLeg!.scheduledDate,
          scheduledTime: _routeLeg!.scheduledTime,
          startLatitude: _routeLeg!.startLatitude,
          startLongitude: _routeLeg!.startLongitude,
          startedAt: _routeLeg!.startedAt,
          endLatitude: _routeLeg!.endLatitude,
          endLongitude: _routeLeg!.endLongitude,
          endedAt: _routeLeg!.endedAt,
          createdAt: _routeLeg!.createdAt,
          distanceMiles: _routeLeg!.distanceMiles,
          durationHours: _routeLeg!.durationHours,
          driverInstructions: _routeLeg!.driverInstructions,
          status: status, // This is the only field we're updating
          locations: _routeLeg!.locations,
          driverAssignments: _routeLeg!.driverAssignments,
          routeId: _routeLeg!.routeId,
        );
      });
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

  Future<void> _beginWork() async {
    final confirm = await _showBeginWorkConfirmation();
    if (confirm) {
      return _updateRouteLegStatus(RouteLegStatus.IN_PROGRESS);
    }
  }

  Future<void> _completeWork() async {
    final confirm = await _showCompleteWorkConfirmation();
    if (confirm) {
      return _updateRouteLegStatus(RouteLegStatus.COMPLETED);
    }
  }

  /// Check if status changes are allowed
  /// Status changes are not allowed if the load has been invoiced and assignment is completed
  bool _canChangeStatus() {
    if (_load?.invoice != null && _routeLeg?.status == RouteLegStatus.COMPLETED) {
      return false;
    }
    return true;
  }

  Future<void> _showStatusChangeOptions(BuildContext context) async {
    // Check if status changes are allowed
    if (!_canChangeStatus()) {
      _showSnackBar('Cannot change status: Assignment has been invoiced and completed', isError: true);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Change Status'),
          message: const Text('Select a new status for this assignment'),
          actions: [
            if (_routeLeg!.status == RouteLegStatus.IN_PROGRESS)
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final confirm = await _showStopWorkConfirmation();
                  if (confirm) {
                    _stopWork();
                  }
                },
                child: const Text('Mark as Assigned'),
              ),
            if (_routeLeg!.status == RouteLegStatus.COMPLETED)
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final confirm = await _showBeginWorkConfirmation();
                  if (confirm) {
                    _beginWorkWithoutConfirm();
                  }
                },
                child: const Text('Mark as In Progress'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                if (_routeLeg!.status == RouteLegStatus.IN_PROGRESS)
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: const Text('Mark as Assigned'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final confirm = await _showStopWorkConfirmation();
                      if (confirm) {
                        _stopWork();
                      }
                    },
                  ),
                if (_routeLeg!.status == RouteLegStatus.COMPLETED)
                  ListTile(
                    leading: const Icon(Icons.play_circle_filled),
                    title: const Text('Mark as In Progress'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final confirm = await _showBeginWorkConfirmation();
                      if (confirm) {
                        _beginWorkWithoutConfirm();
                      }
                    },
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd', 'en_US').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'Assignment Details',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
          backgroundColor: AppThemes.getCardColor(context),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isRefreshing ? null : _refreshAssignmentDetails,
            child: _isRefreshing
                ? const CupertinoActivityIndicator(radius: 10)
                : Icon(
                    CupertinoIcons.refresh,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
        ),
        child: Stack(
          children: [
            _buildContent(),
            _buildFixedActionButtons(),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Assignment Details',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
          backgroundColor: AppThemes.getCardColor(context),
          foregroundColor: AppThemes.getPrimaryTextColor(context),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: _isRefreshing ? null : _refreshAssignmentDetails,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getSecondaryTextColor(context)),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: AppThemes.getSecondaryTextColor(context),
                    ),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildContent(),
            _buildFixedActionButtons(),
          ],
        ),
      );
    }
  }

  Widget _buildContent() {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        color: AppThemes.getPrimaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildAssignmentDetails(),
    );
  }

  Widget _buildLoadingView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      color: AppThemes.getBackgroundColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (defaultTargetPlatform == TargetPlatform.iOS)
              CupertinoActivityIndicator(
                radius: 20,
                color: AppThemes.getSecondaryTextColor(context),
              )
            else
              CircularProgressIndicator(
                color: AppThemes.getSecondaryTextColor(context),
                strokeWidth: 3,
              ),
            SizedBox(height: isCompact ? 16 : 20),
            Text(
              'Loading assignment details...',
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
                color: AppThemes.getPrimaryTextColor(context),
                letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.2 : 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentDetails() {
    // Double check that data is available
    if (_load == null || _routeLeg == null) {
      return _buildLoadingView();
    }
    return _buildScrollableContent();
  }

  Widget _buildScrollableContent() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoScrollbar(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildDetailsContent(),
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: _buildDetailsContent(),
      );
    }
  }

  Widget _buildDetailsContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final isTablet = screenWidth >= 768;

    return Container(
      color: AppThemes.getBackgroundColor(context),
      child: Column(
        children: [
          // Status and key info section
          _buildStatusSection(isCompact, isTablet),

          // Documents section
          _buildDocumentsSection(isCompact, isTablet),

          // Assignment info section
          _buildAssignmentInfoSection(isCompact, isTablet),

          // Route details section
          _buildRouteSection(isCompact, isTablet),

          // Drivers section
          _buildDriversSection(isCompact, isTablet),

          SizedBox(
              height:
                  defaultTargetPlatform == TargetPlatform.iOS ? 120 : 140), // Increased bottom spacing to avoid clipping by fixed buttons
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isCompact, bool isTablet) {
    final status = _routeLeg!.status;

    // Status colors with theme-aware accents
    Color statusAccentColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case RouteLegStatus.ASSIGNED:
        statusAccentColor = const Color(0xFF3B82F6); // Blue accent
        statusIcon = Icons.assignment;
        statusText = 'ASSIGNED';
        break;
      case RouteLegStatus.IN_PROGRESS:
        statusAccentColor = const Color(0xFF10B981); // Green accent
        statusIcon = Icons.play_circle_filled;
        statusText = 'IN PROGRESS';
        break;
      case RouteLegStatus.COMPLETED:
        statusAccentColor = const Color(0xFF059669); // Darker green accent
        statusIcon = Icons.check_circle;
        statusText = 'COMPLETED';
        break;
    }

    // Apply neumorphic active styling for IN_PROGRESS status
    bool isActiveStatus = status == RouteLegStatus.IN_PROGRESS;

    Widget statusCard = Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: isActiveStatus ? AppThemes.getNeumorphicBackgroundColor(context) : AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: isActiveStatus
            ? null // No border for active neumorphic state
            : Border.all(
                color: AppThemes.getBorderColor(context),
                width: 1,
              ),
        boxShadow: isActiveStatus
            ? AppThemes.getNeumorphicShadows(context, isPressed: true)
            : [
                // Standard shadow for inactive states
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF000000).withOpacity(0.04)
                      : const Color(0xFF000000).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActiveStatus ? AppThemes.getNeumorphicBackgroundColor(context) : AppThemes.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: isActiveStatus
                      ? null // No border for active neumorphic state
                      : Border.all(
                          color: statusAccentColor.withOpacity(0.2), // Subtle accent border
                          width: 1,
                        ),
                  boxShadow: isActiveStatus ? AppThemes.getNeumorphicBadgeShadows(context) : null, // No shadow for inactive state
                ),
                child: Icon(
                  statusIcon,
                  color: statusAccentColor, // Status accent color for icon
                  size: isCompact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: _fontFamily,
                        color: AppThemes.getPrimaryTextColor(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ORDER #${_load!.refNum}',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: _fontFamily,
                        color: AppThemes.getSecondaryTextColor(context),
                        letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.3 : 0.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Three-dot menu for status changes
              if ((_routeLeg!.status == RouteLegStatus.IN_PROGRESS || _routeLeg!.status == RouteLegStatus.COMPLETED) && _canChangeStatus())
                IconButton(
                  onPressed: () => _showStatusChangeOptions(context),
                  icon: Icon(
                    Icons.more_vert,
                    color: AppThemes.getSecondaryTextColor(context),
                    size: 24,
                  ),
                  tooltip: 'Change Status',
                ),
            ],
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 20 : 16,
      ),
      child: defaultTargetPlatform == TargetPlatform.iOS
          ? _buildCupertinoTappableCard(statusCard, isTablet, isCompact, isActiveStatus)
          : _buildMaterialTappableCard(statusCard, isTablet, isCompact, isActiveStatus),
    );
  }

  // Helper methods for UI sections
  Widget _buildDriversSection(bool isCompact, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF000000).withOpacity(0.04)
                : const Color(0xFF000000).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DRIVERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: _fontFamily,
              color: AppThemes.getSecondaryTextColor(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildDriversList(isCompact),
        ],
      ),
    );
  }

  List<Widget> _buildDriversList(bool isCompact) {
    final driverAssignments = _routeLeg!.driverAssignments;
    return driverAssignments.asMap().entries.map((entry) {
      final index = entry.key;
      final assignment = entry.value;
      final isLast = index == driverAssignments.length - 1;

      return Column(
        children: [
          _buildDriverItem(assignment.driver, isCompact),
          if (!isLast) const SizedBox(height: 8),
        ],
      );
    }).toList();
  }

  Widget _buildDriverItem(Driver driver, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppThemes.getNeumorphicBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppThemes.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemes.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person,
              color: AppThemes.getSecondaryTextColor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              driver.name,
              style: TextStyle(
                fontSize: isCompact ? 14 : 15,
                fontWeight: FontWeight.w600,
                fontFamily: _fontFamily,
                color: AppThemes.getPrimaryTextColor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedActionButtons() {
    // Don't show action buttons while loading or if data is not available
    if (_isLoading || _routeLeg == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            defaultTargetPlatform == TargetPlatform.iOS
                ? MediaQuery.of(context).padding.bottom + 8
                : MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          border: Border(
            top: BorderSide(
              color: AppThemes.getBorderColor(context),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF000000).withOpacity(0.08)
                  : const Color(0xFF000000).withOpacity(0.3),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: _buildActionButtons(),
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    // Use null-safe access just in case
    final routeLegStatus = _routeLeg?.status;
    if (routeLegStatus == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (routeLegStatus == RouteLegStatus.ASSIGNED) Expanded(child: _buildModernBeginWorkButton(isCompact)),
        if (routeLegStatus == RouteLegStatus.IN_PROGRESS) Expanded(child: _buildModernCompleteWorkButton(isCompact)),
        if (routeLegStatus == RouteLegStatus.COMPLETED) Expanded(child: _buildAssignmentStatusWidget(isCompact)),
      ],
    );
  }

  Widget _buildAssignmentStatusWidget(bool isCompact) {
    final loadStatus = _load?.status;
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (loadStatus) {
      case LoadStatus.DELIVERED:
        statusText = 'Completed';
        statusColor = const Color(0xFF10B981); // Green
        statusIcon = defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle;
        break;
      case LoadStatus.POD_READY:
        statusText = 'POD Ready';
        statusColor = const Color(0xFF3B82F6); // Blue
        statusIcon = defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.doc_checkmark_fill : Icons.assignment_turned_in;
        break;
      default:
        // Fallback for COMPLETED route leg status
        statusText = 'Completed';
        statusColor = const Color(0xFF10B981); // Green
        statusIcon = defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle;
        break;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 12 : 16,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: isCompact ? 20 : 22, // Increased from 17:19
            fontWeight: FontWeight.w700,
            fontFamily: _fontFamily,
            color: statusColor,
            decoration: TextDecoration.none,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: isCompact ? 28 : 32, // Increased from 24:28
              ),
              const SizedBox(width: 12),
              Text(statusText),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 12 : 16,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: isCompact ? 20 : 22, // Increased from 17:18
            fontWeight: FontWeight.w700,
            fontFamily: _fontFamily,
            color: statusColor,
            decoration: TextDecoration.none,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: isCompact ? 28 : 32, // Increased from 24:28
              ),
              const SizedBox(width: 12),
              Text(statusText),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRouteSection(bool isCompact, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF000000).withOpacity(0.04)
                : const Color(0xFF000000).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ROUTE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemes.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_routeLeg!.distanceMiles.toStringAsFixed(0)} mi • ${_formatDuration(_routeLeg!.durationHours)}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Open Route in Maps button
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            child: defaultTargetPlatform == TargetPlatform.iOS
                ? CupertinoButton(
                    onPressed: _openRouteInMaps,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    borderRadius: BorderRadius.circular(12),
                    color: AppThemes.getButtonBackgroundColor(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          size: 20,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Open Route in Maps',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: AppThemes.getPrimaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _openRouteInMaps,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemes.getSecondaryTextColor(context),
                      side: BorderSide(color: AppThemes.getBorderColor(context), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppThemes.getButtonBackgroundColor(context),
                    ),
                    icon: Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: AppThemes.getSecondaryTextColor(context),
                    ),
                    label: Text(
                      'Open Route in Maps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: AppThemes.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
          ),

          _buildVisualRouteFlow(isCompact),
        ],
      ),
    );
  }

  Widget _buildVisualRouteFlow(bool isCompact) {
    final locations = _routeLeg!.locations;
    final stopCount = locations.length - 2;

    return Column(
      children: [
        // Pickup location
        _buildSequentialLocationStop(
          location: locations.first,
          type: 'PICKUP',
          color: const Color(0xFF059669),
          isCompact: isCompact,
          isFirst: true,
          isLast: false,
        ),

        // Intermediate stops (if any)
        if (stopCount > 0) ...[
          for (int i = 1; i < locations.length - 1; i++)
            _buildSequentialLocationStop(
              location: locations[i],
              type: 'STOP ${i}',
              color: const Color(0xFF3B82F6),
              isCompact: isCompact,
              isFirst: false,
              isLast: false,
            ),
        ],

        // Delivery location
        _buildSequentialLocationStop(
          location: locations.last,
          type: 'DELIVERY',
          color: const Color(0xFFDC2626),
          isCompact: isCompact,
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSequentialLocationStop({
    required RouteLegLocation location,
    required String type,
    required Color color,
    required bool isCompact,
    required bool isFirst,
    required bool isLast,
  }) {
    final stop = location.loadStop;
    final loc = location.location;

    final locationName = _getLocationName(location);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection line and map icon column
            Container(
              width: 32,
              child: Column(
                children: [
                  // Top connecting line (except for first stop)
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 28, // Extended height to bridge the gap from previous stop
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB), // More visible connection line
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                  // Map icon with colored background - smaller and more compact
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppThemes.getBackgroundColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color, // Keep status color for functional differentiation
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.place,
                      size: 16,
                      color: color, // Status color for icon
                    ),
                  ),

                  // Bottom connecting line (except for last stop)
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28, // Extended height to bridge the 12px gap between stops
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB), // More visible connection line
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Location information
            Expanded(
              child: defaultTargetPlatform == TargetPlatform.iOS
                  ? GestureDetector(
                      onTap: () {
                        // Optional: Add action like showing location details
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.all(isCompact ? 12 : 16),
                        decoration: BoxDecoration(
                          color: AppThemes.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppThemes.getBorderColor(context),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type label with datetime badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppThemes.getBackgroundColor(context),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppThemes.getBorderColor(context),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _fontFamily,
                                      color: AppThemes.getSecondaryTextColor(context),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Divider and datetime badge for stops
                                if (stop != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 12,
                                    color: AppThemes.getBorderColor(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppThemes.getBackgroundColor(context),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppThemes.getBorderColor(context),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${_formatDate(stop.date)} at ${stop.time}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: _fontFamily,
                                        color: AppThemes.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Location name
                            if (locationName.isNotEmpty)
                              Text(
                                locationName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: _fontFamily,
                                  color: AppThemes.getPrimaryTextColor(context),
                                  letterSpacing: -0.1,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                            // Address and city/state
                            if (stop != null) ...[
                              if (locationName.isNotEmpty) const SizedBox(height: 6),
                              // Full address with single copy and map icons
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stop.street.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: isCompact ? 13 : 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: _fontFamily,
                                            color: AppThemes.getPrimaryTextColor(context),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}',
                                          style: TextStyle(
                                            fontSize: isCompact ? 13 : 14,
                                            fontWeight: FontWeight.w500, // Same weight as street
                                            fontFamily: _fontFamily,
                                            color: AppThemes.getPrimaryTextColor(context),
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Copy address button
                                  GestureDetector(
                                    onTap: () => _copyAddressToClipboard(
                                        '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (_copiedAddresses[
                                                    '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                true)
                                            ? const Color(0xFFF0FDF4) // Light green background when copied
                                            : AppThemes.getCardColor(context),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (_copiedAddresses[
                                                      '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                  true)
                                              ? const Color(0xFF22C55E) // Green border when copied
                                              : AppThemes.getBorderColor(context),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        (_copiedAddresses[
                                                    '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                true)
                                            ? Icons.check_rounded // Checkmark when copied
                                            : Icons.content_copy_rounded, // Copy icon normally
                                        size: 14,
                                        color: (_copiedAddresses[
                                                    '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                true)
                                            ? const Color(0xFF22C55E) // Green checkmark
                                            : AppThemes.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Additional stop information (PO, Pickup, Reference numbers)
                              if (stop.poNumbers?.isNotEmpty == true ||
                                  stop.pickUpNumbers?.isNotEmpty == true ||
                                  stop.referenceNumbers?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppThemes.getCardColor(context),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppThemes.getBorderColor(context),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (stop.poNumbers?.isNotEmpty == true) ...[
                                        _buildStopInfoRow('PO Number:', stop.poNumbers!, isCompact),
                                        const SizedBox(height: 4),
                                      ],
                                      if (stop.pickUpNumbers?.isNotEmpty == true) ...[
                                        _buildStopInfoRow('Pickup Number:', stop.pickUpNumbers!, isCompact),
                                        const SizedBox(height: 4),
                                      ],
                                      if (stop.referenceNumbers?.isNotEmpty == true) ...[
                                        _buildStopInfoRow('Reference Number:', stop.referenceNumbers!, isCompact),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ] else if (loc != null) ...[
                              if (locationName.isNotEmpty) const SizedBox(height: 6),
                              // Full address with single copy and map icons
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.street.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: isCompact ? 13 : 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: _fontFamily,
                                            color: AppThemes.getPrimaryTextColor(context),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}',
                                          style: TextStyle(
                                            fontSize: isCompact ? 13 : 14,
                                            fontWeight: FontWeight.w500, // Same weight as street
                                            fontFamily: _fontFamily,
                                            color: AppThemes.getPrimaryTextColor(context),
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Copy address button
                                  GestureDetector(
                                    onTap: () => _copyAddressToClipboard(
                                        '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (_copiedAddresses[
                                                    '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                true)
                                            ? const Color(0xFFF0FDF4) // Light green background when copied
                                            : AppThemes.getCardColor(context),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (_copiedAddresses[
                                                      '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                  true)
                                              ? const Color(0xFF22C55E) // Green border when copied
                                              : AppThemes.getBorderColor(context),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        (_copiedAddresses[
                                                    '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                true)
                                            ? Icons.check_rounded // Checkmark when copied
                                            : Icons.content_copy_rounded, // Copy icon normally
                                        size: 14,
                                        color: (_copiedAddresses[
                                                    '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                true)
                                            ? const Color(0xFF22C55E) // Green checkmark
                                            : AppThemes.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Optional: Add action like showing location details
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          padding: EdgeInsets.all(isCompact ? 12 : 16),
                          decoration: BoxDecoration(
                            color: AppThemes.getCardColor(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppThemes.getBorderColor(context),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type label with datetime badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppThemes.getCardColor(context),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppThemes.getBorderColor(context),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: _fontFamily,
                                        color: AppThemes.getSecondaryTextColor(context),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  // Divider and datetime badge for stops
                                  if (stop != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: AppThemes.getBorderColor(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppThemes.getCardColor(context),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppThemes.getBorderColor(context),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        '${_formatDate(stop.date)} at ${stop.time}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: _fontFamily,
                                          color: AppThemes.getSecondaryTextColor(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Location name
                              if (locationName.isNotEmpty)
                                Text(
                                  locationName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: _fontFamily,
                                    color: AppThemes.getPrimaryTextColor(context),
                                    letterSpacing: -0.1,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              // Address and contact info
                              if (stop != null) ...[
                                const SizedBox(height: 8),

                                // Copyable address
                                GestureDetector(
                                  onTap: () => _copyAddressToClipboard(
                                      '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _copiedAddresses[
                                                  '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                              true
                                          ? const Color(0xFF10B981).withOpacity(0.1) // Success green highlight
                                          : AppThemes.getBorderColor(context).withOpacity(0.3), // Subtle highlight
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _copiedAddresses[
                                                    '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                true
                                            ? const Color(0xFF10B981).withOpacity(0.3)
                                            : AppThemes.getBorderColor(context),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}',
                                            style: TextStyle(
                                              fontSize: isCompact ? 11 : 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: _fontFamily,
                                              color: AppThemes.getSecondaryTextColor(context),
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _copiedAddresses[
                                                      '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                  true
                                              ? Icons.check
                                              : Icons.copy,
                                          size: 14,
                                          color: _copiedAddresses[
                                                      '${stop.street.toUpperCase()}, ${stop.city.toUpperCase()}, ${stop.state.toUpperCase()} ${stop.zip}'] ==
                                                  true
                                              ? const Color(0xFF10B981) // Success green
                                              : AppThemes.getSecondaryTextColor(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Additional info can be added here for stops if needed
                              ] else if (loc != null) ...[
                                const SizedBox(height: 8),

                                // Copyable address for location
                                GestureDetector(
                                  onTap: () => _copyAddressToClipboard(
                                      '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _copiedAddresses[
                                                  '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                              true
                                          ? const Color(0xFF10B981).withOpacity(0.1) // Success green highlight
                                          : AppThemes.getBorderColor(context).withOpacity(0.3), // Subtle highlight
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _copiedAddresses[
                                                    '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                true
                                            ? const Color(0xFF10B981).withOpacity(0.3)
                                            : AppThemes.getBorderColor(context),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}',
                                            style: TextStyle(
                                              fontSize: isCompact ? 11 : 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: _fontFamily,
                                              color: AppThemes.getSecondaryTextColor(context),
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _copiedAddresses[
                                                      '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                  true
                                              ? Icons.check
                                              : Icons.copy,
                                          size: 14,
                                          color: _copiedAddresses[
                                                      '${loc.street.toUpperCase()}, ${loc.city.toUpperCase()}, ${loc.state.toUpperCase()} ${loc.zip}'] ==
                                                  true
                                              ? const Color(0xFF10B981) // Success green
                                              : AppThemes.getSecondaryTextColor(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),

        // Add spacing between stops (except after last stop)
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  // Copy address to clipboard
  void _copyAddressToClipboard(String address) {
    if (address.trim().isNotEmpty) {
      // Import Clipboard from services package
      Clipboard.setData(ClipboardData(text: address));
      _showSnackBar('Address copied to clipboard', isError: false);

      // Set the copied state for this address
      setState(() {
        _copiedAddresses[address] = true;
      });

      // Reset the state after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _copiedAddresses[address] = false;
          });
        }
      });
    }
  }

  // Show snack bar helper
  void _showSnackBar(String message, {required bool isError}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS, wrap with DefaultTextStyle to prevent yellow border issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DefaultTextStyle(
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
            child: Text(message),
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String _getLocationName(RouteLegLocation legLocation) {
    if (legLocation.loadStop != null) {
      return legLocation.loadStop!.name;
    } else if (legLocation.location != null) {
      return legLocation.location!.name;
    }
    return '';
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }

  Widget _buildDocumentStatusNote(bool isCompact, bool isTablet) {
    final status = _routeLeg!.status;
    String noteText;
    IconData noteIcon;
    Color noteColor;

    switch (status) {
      case RouteLegStatus.IN_PROGRESS:
        noteText = 'Please upload BOL (Bill of Lading) paperwork after pickup. The broker needs this as proof of pickup.';
        noteIcon = defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.doc_text : Icons.description;
        noteColor = const Color(0xFF3B82F6); // Blue
        break;
      case RouteLegStatus.COMPLETED:
        noteText = 'Please upload POD (Proof of Delivery) paperwork for load invoicing and payment processing.';
        noteIcon = defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.checkmark_circle : Icons.assignment_turned_in;
        noteColor = const Color(0xFF10B981); // Green
        break;
      default:
        return const SizedBox.shrink(); // Don't show note for ASSIGNED status
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: 8,
        ),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: noteColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: noteColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              noteIcon,
              color: noteColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                noteText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: noteColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: noteColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              noteIcon,
              color: noteColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                noteText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentsSection(bool isCompact, bool isTablet) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: AppThemes.getBorderColor(context),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 20 : 16,
                isTablet ? 20 : 16,
                isTablet ? 20 : 16,
                8,
              ),
              child: Text(
                'DOCUMENTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: -0.08,
                ),
              ),
            ),
            // Status-based note for drivers
            _buildDocumentStatusNote(isCompact, isTablet),
            // Show grouped documents (BOL, POD, Documents) sorted by updated date
            ..._buildGroupedDocuments(isCompact, true),
            // Show uploading state if document is being uploaded
            if (_isUploadingDocument) _buildCupertinoUploadingItem(isCompact),

            // Always show the three upload buttons
            _buildCupertinoDocumentButtons(isCompact, isTablet),

            // Add bottom margin for consistent spacing
            SizedBox(height: isTablet ? 12 : 8),
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: AppThemes.getBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF000000).withOpacity(0.04)
                  : const Color(0xFF000000).withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DOCUMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Status-based note for drivers
            _buildDocumentStatusNote(isCompact, isTablet),
            // Show grouped documents (BOL, POD, Documents) sorted by updated date
            ..._buildGroupedDocuments(isCompact, false),
            // Show uploading state if document is being uploaded
            if (_isUploadingDocument) _buildMaterialUploadingItem(isCompact),

            // Always show the three upload buttons
            _buildMaterialDocumentButtons(isCompact, isTablet),

            // Add bottom margin for consistent spacing
            SizedBox(height: isTablet ? 12 : 8),
          ],
        ),
      );
    }
  }

  Widget _buildCupertinoDocumentButtons(bool isCompact, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          // Upload BOL Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: CupertinoButton(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'BOL'),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompact ? 14 : 16,
              ),
              color: AppThemes.getButtonBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 20,
                    color: AppThemes.getPrimaryTextColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload BOL',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upload POD Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: CupertinoButton(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'POD'),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompact ? 14 : 16,
              ),
              color: AppThemes.getButtonBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal,
                    size: 20,
                    color: AppThemes.getPrimaryTextColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload POD',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upload Document Button
          Container(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'Document'),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompact ? 14 : 16,
              ),
              color: AppThemes.getButtonBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.folder,
                    size: 20,
                    color: AppThemes.getPrimaryTextColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialDocumentButtons(bool isCompact, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Upload BOL Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'BOL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0), // Blue foreground
                side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isCompact ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: AppThemes.getButtonBackgroundColor(context),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(
                'Upload BOL',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                ),
              ),
            ),
          ),

          // Upload POD Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'POD'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32), // Green foreground
                side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isCompact ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: AppThemes.getButtonBackgroundColor(context),
              ),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(
                'Upload POD',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                ),
              ),
            ),
          ),

          // Upload Document Button
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPickOptionsDialog(context, documentType: 'Document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF616161), // Grey foreground
                side: const BorderSide(color: Color(0xFF616161), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isCompact ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: AppThemes.getButtonBackgroundColor(context),
              ),
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoDocumentItem(LoadDocument doc, bool isCompact, String documentType) {
    final isDocumentDeleting = _deletingDocuments.contains(doc.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDocumentDeleting ? AppThemes.getBackgroundColor(context).withOpacity(0.5) : AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 0.5,
        ),
      ),
      child: CupertinoListTile(
        backgroundColor: Colors.transparent, // Make background transparent since container handles it
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        ),
        onTap: isDocumentDeleting ? null : () => _viewDocument(doc),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppThemes.getNeumorphicBackgroundColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppThemes.getBorderColor(context),
              width: 0.5,
            ),
          ),
          child: Icon(
            _getFileIcon(doc.fileType),
            color: AppThemes.getSecondaryTextColor(context),
            size: 14,
          ),
        ),
        title: Text(
          doc.fileName,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            fontFamily: _fontFamily,
            color: isDocumentDeleting ? AppThemes.getSecondaryTextColor(context) : AppThemes.getPrimaryTextColor(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Document type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppThemes.getBorderColor(context),
                  width: 0.5,
                ),
              ),
              child: Text(
                documentType,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Divider
            Text(
              '•',
              style: TextStyle(
                fontSize: 10,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(width: 6),
            // File size
            Text(
              _formatFileSize(doc.fileSize),
              style: TextStyle(
                fontSize: 11,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
        trailing: isDocumentDeleting
            ? const CupertinoActivityIndicator(
                radius: 8,
                color: CupertinoColors.tertiaryLabel,
              )
            : (_load!.invoice?.id == null && _canDeleteDocument(doc))
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _deleteDocument(doc.id!),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: CupertinoColors.systemRed,
                      size: 18,
                    ),
                  )
                : null,
      ),
    );
  }

  Widget _buildMaterialDocumentItem(LoadDocument doc, bool isCompact, String documentType) {
    final isDocumentDeleting = _deletingDocuments.contains(doc.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDocumentDeleting ? AppThemes.getBackgroundColor(context).withOpacity(0.5) : AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
      ),
      child: ListTile(
        enabled: !isDocumentDeleting,
        onTap: isDocumentDeleting ? null : () => _viewDocument(doc),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 4 : 6,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppThemes.getNeumorphicBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppThemes.getBorderColor(context),
              width: 1,
            ),
          ),
          child: Icon(
            _getMaterialFileIcon(doc.fileType),
            color: AppThemes.getSecondaryTextColor(context),
            size: 16,
          ),
        ),
        title: Text(
          doc.fileName,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            color: isDocumentDeleting ? AppThemes.getSecondaryTextColor(context) : AppThemes.getPrimaryTextColor(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Document type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppThemes.getBorderColor(context),
                  width: 0.5,
                ),
              ),
              child: Text(
                documentType,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Divider
            Text(
              '•',
              style: TextStyle(
                fontSize: 10,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(width: 6),
            // File size
            Text(
              _formatFileSize(doc.fileSize),
              style: TextStyle(
                fontSize: 11,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
        trailing: isDocumentDeleting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              )
            : (_load!.invoice?.id == null && _canDeleteDocument(doc))
                ? IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444), // Red accent for delete action
                    ),
                    onPressed: () => _deleteDocument(doc.id!),
                  )
                : null,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Platform-specific tappable card implementations
  Widget _buildCupertinoTappableCard(Widget statusCard, bool isTablet, bool isCompact, bool isActiveStatus) {
    return GestureDetector(
      onTap: () {
        // Add haptic feedback for iOS
        HapticFeedback.lightImpact();
        // Optional: Add action like expanding/collapsing details
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: isActiveStatus ? 200 : 150),
        curve: isActiveStatus ? Curves.easeInOut : Curves.easeInOut,
        child: statusCard,
      ),
    );
  }

  Widget _buildMaterialTappableCard(Widget statusCard, bool isTablet, bool isCompact, bool isActiveStatus) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback for Material
          HapticFeedback.lightImpact();
          // Optional: Add action like expanding/collapsing details
        },
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        splashColor: isActiveStatus
            ? const Color(0xFF10B981).withOpacity(0.1) // Green splash for active state
            : const Color(0xFF3B82F6).withOpacity(0.1), // Blue splash for inactive
        highlightColor: isActiveStatus
            ? const Color(0xFF10B981).withOpacity(0.05) // Green highlight for active state
            : const Color(0xFF3B82F6).withOpacity(0.05), // Blue highlight for inactive
        child: AnimatedContainer(
          duration: Duration(milliseconds: isActiveStatus ? 200 : 150),
          curve: Curves.easeInOut,
          child: statusCard,
        ),
      ),
    );
  }

  // File viewing methods
  Future<void> _viewDocument(LoadDocument doc) async {
    try {
      if (_isImageFile(doc.fileType)) {
        await _viewImage(doc);
      } else if (_isPdfFile(doc.fileType)) {
        await _viewPdf(doc);
      } else {
        await _openWithExternalApp(doc);
      }
    } catch (e) {
      _showSnackBar('Error opening document: $e', isError: true);
    }
  }

  bool _isImageFile(String fileType) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileType.toLowerCase());
  }

  bool _isPdfFile(String fileType) {
    return fileType.toLowerCase() == 'pdf';
  }

  Future<void> _viewImage(LoadDocument doc) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerPage(
          imageUrl: doc.fileUrl,
          title: doc.fileName,
        ),
      ),
    );
  }

  Future<void> _viewPdf(LoadDocument doc) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PdfViewerPage(
          pdfUrl: doc.fileUrl,
          title: doc.fileName,
        ),
      ),
    );
  }

  Future<void> _openWithExternalApp(LoadDocument doc) async {
    try {
      final Uri url = Uri.parse(doc.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Cannot open this file type', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e', isError: true);
    }
  }

  // File icon helpers
  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (_isImageFile(type)) {
      return CupertinoIcons.photo;
    } else if (_isPdfFile(type)) {
      return CupertinoIcons.doc_text;
    } else {
      return CupertinoIcons.doc;
    }
  }

  IconData _getMaterialFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (_isImageFile(type)) {
      return Icons.image_outlined;
    } else if (_isPdfFile(type)) {
      return Icons.picture_as_pdf_outlined;
    } else {
      return Icons.description_outlined;
    }
  }

  // Uploading item widgets
  Widget _buildCupertinoUploadingItem(bool isCompact) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Light monochrome background for uploading state
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD1D5DB), // Slightly darker border for uploading
          width: 1,
        ),
      ),
      child: CupertinoListTile(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        ),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB), // Light monochrome background
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD1D5DB), // Monochrome border
              width: 1,
            ),
          ),
          child: Icon(
            CupertinoIcons.cloud_upload,
            color: AppThemes.getSecondaryTextColor(context),
            size: 14,
          ),
        ),
        title: Text(
          'Uploading document...',
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            fontFamily: _fontFamily,
            color: AppThemes.getPrimaryTextColor(context),
          ),
        ),
        subtitle: Text(
          'Please wait',
          style: TextStyle(
            fontSize: 11,
            fontFamily: _fontFamily,
            color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
        trailing: CupertinoActivityIndicator(
          radius: 8,
          color: AppThemes.getSecondaryTextColor(context),
        ),
      ),
    );
  }

  Widget _buildMaterialUploadingItem(bool isCompact) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Light monochrome background for uploading state
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD1D5DB), // Slightly darker border for uploading
          width: 1,
        ),
      ),
      child: ListTile(
        enabled: false, // Disable interaction during upload
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 4 : 6,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppThemes.getNeumorphicBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppThemes.getBorderColor(context),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: AppThemes.getSecondaryTextColor(context),
            size: 16,
          ),
        ),
        title: Text(
          'Uploading document...',
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            color: AppThemes.getPrimaryTextColor(context),
          ),
        ),
        subtitle: Text(
          'Please wait',
          style: TextStyle(
            fontSize: 11,
            fontFamily: _fontFamily,
            color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentInfoSection(bool isCompact, bool isTablet) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: AppThemes.getBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF000000).withOpacity(0.04)
                  : const Color(0xFF000000).withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 20 : 16,
                isTablet ? 20 : 16,
                isTablet ? 20 : 16,
                8,
              ),
              child: Text(
                'ASSIGNMENT INFO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: -0.08,
                ),
              ),
            ),
            // Notes section moved to top with enhanced highlighting
            if (_routeLeg!.driverInstructions.isNotEmpty)
              _buildCupertinoNotesRow(
                _routeLeg!.driverInstructions,
                isCompact,
                isTablet,
              ),
            _buildCupertinoInfoRow(
              'Start Time',
              '${_formatDate(_routeLeg!.scheduledDate!)} at ${DateFormat("hh:mm a").format(DateFormat("HH:mm").parse(_routeLeg!.scheduledTime))}',
              CupertinoIcons.clock,
              isCompact,
            ),
            _buildCupertinoInfoRow(
              'Distance',
              '${_routeLeg!.distanceMiles.toStringAsFixed(1)} miles',
              CupertinoIcons.location,
              isCompact,
            ),
            _buildCupertinoInfoRow(
              'Duration',
              hoursToReadable(_routeLeg!.durationHours),
              CupertinoIcons.timer,
              isCompact,
              isLast: true,
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: AppThemes.getBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSIGNMENT INFO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Notes section moved to top with enhanced highlighting
            if (_routeLeg!.driverInstructions.isNotEmpty)
              _buildMaterialNotesRow(
                _routeLeg!.driverInstructions,
                isCompact,
                isTablet,
              ),
            _buildMaterialInfoRow(
              'Start Time',
              '${_formatDate(_routeLeg!.scheduledDate!)} at ${DateFormat("hh:mm a").format(DateFormat("HH:mm").parse(_routeLeg!.scheduledTime))}',
              Icons.access_time,
              isCompact,
            ),
            _buildMaterialInfoRow(
              'Distance',
              '${_routeLeg!.distanceMiles.toStringAsFixed(1)} miles',
              Icons.straighten,
              isCompact,
            ),
            _buildMaterialInfoRow(
              'Duration',
              hoursToReadable(_routeLeg!.durationHours),
              Icons.timer_outlined,
              isCompact,
              isLast: true,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCupertinoInfoRow(String label, String value, IconData icon, bool isCompact, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppThemes.getBorderColor(context),
                  width: 0.5,
                ),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 12 : 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppThemes.getBackgroundColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemes.getBorderColor(context),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 14,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: AppThemes.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isCompact ? 15 : 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced notes row for iOS with Apple Design Guidelines
  Widget _buildCupertinoNotesRow(String notes, bool isCompact, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        // Theme-aware background
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(10), // Apple's standard corner radius
        // Subtle shadow following Apple's depth principles
        boxShadow: AppThemes.getNeumorphicShadows(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          // Apple-style accent strip on the left
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: CupertinoColors.systemOrange,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header following Apple's typography hierarchy
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 16,
                      color: CupertinoColors.systemOrange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Driver Instructions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: AppThemes.getPrimaryTextColor(context),
                        letterSpacing: -0.08, // Apple's preferred letter spacing
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Content following Apple's reading typography
                Text(
                  notes,
                  style: TextStyle(
                    fontSize: isCompact ? 15 : 16, // Apple's body text size
                    fontWeight: FontWeight.w400, // Apple's regular weight
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    height: 1.4286, // Apple's line height ratio (20/14)
                    letterSpacing: -0.24, // Apple's body text spacing
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced notes row for Material with Material Design principles
  Widget _buildMaterialNotesRow(String notes, bool isCompact, bool isTablet) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2, // Material Design elevation
      color: AppThemes.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Material rounded corners
        side: BorderSide(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header following Material Design typography scale
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemes.getNeumorphicBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Driver Instructions',
                  style: TextStyle(
                    fontSize: 14, // Material Design labelLarge
                    fontWeight: FontWeight.w500, // Material medium weight
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    letterSpacing: 0.1, // Material Design letter spacing
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Content following Material Design bodyLarge
            Text(
              notes,
              style: TextStyle(
                fontSize: isCompact ? 14 : 16, // Material bodyLarge
                fontWeight: FontWeight.w400, // Material regular weight
                fontFamily: _fontFamily,
                color: AppThemes.getPrimaryTextColor(context),
                height: 1.5, // Material Design line height
                letterSpacing: 0.15, // Material body text spacing
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInfoRow(String label, String value, IconData icon, bool isCompact, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemes.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemes.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppThemes.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppThemes.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build stop information rows (PO, Pickup, Reference numbers)
  Widget _buildStopInfoRow(String label, String value, bool isCompact) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w500,
              fontFamily: _fontFamily,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // Modern button designs
  Widget _buildModernBeginWorkButton(bool isCompact) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        height: isCompact ? 48 : 52,
        child: CupertinoButton.filled(
          onPressed: _isStatusChangeLoading ? null : _beginWork,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          child: _isStatusChangeLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      child: const CupertinoActivityIndicator(
                        color: Color(0xFF1E3A8A), // Dark blue color
                        radius: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Starting Work...',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: const Color(0xFF1E3A8A), // Dark blue color
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.play_fill, size: 20, color: CupertinoColors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Begin Work',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      );
    } else {
      return Container(
        height: isCompact ? 48 : 52,
        child: ElevatedButton(
          onPressed: _isStatusChangeLoading ? null : _beginWork,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Keep consistent green color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _isStatusChangeLoading ? 0 : 2,
            shadowColor: _isStatusChangeLoading ? Colors.transparent : const Color(0xFF10B981).withOpacity(0.3),
          ),
          child: _isStatusChangeLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1E3A8A), // Dark blue color
                        backgroundColor: Color(0x30FFFFFF), // More subtle background
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Starting Work...',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: const Color(0xFF1E3A8A), // Dark blue color
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Begin Work',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
  }

  Widget _buildModernCompleteWorkButton(bool isCompact) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        height: isCompact ? 48 : 52,
        child: CupertinoButton.filled(
          onPressed: _isStatusChangeLoading ? null : _completeWork,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          child: _isStatusChangeLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(
                      color: Color(0xFF1E3A8A), // Dark blue color
                      radius: 10,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Completing...',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: const Color(0xFF1E3A8A), // Dark blue color
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.check_mark_circled_solid, size: 20, color: CupertinoColors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Complete Work',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      );
    } else {
      return Container(
        height: isCompact ? 48 : 52,
        child: ElevatedButton(
          onPressed: _isStatusChangeLoading ? null : _completeWork,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isStatusChangeLoading ? const Color(0xFF9CA3AF) : const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isStatusChangeLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1E3A8A), // Dark blue color
                        backgroundColor: Color(0x40FFFFFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Completing...',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: const Color(0xFF1E3A8A), // Dark blue color
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Complete Work',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
  }

  Widget _buildModernUploadButton(bool isCompact) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        height: isCompact ? 48 : 52,
        child: CupertinoButton.filled(
          onPressed: _isStatusChangeLoading ? null : () => _showPickOptionsDialog(context),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.cloud_upload_fill, size: 20, color: CupertinoColors.white),
              const SizedBox(width: 8),
              Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        height: isCompact ? 48 : 52,
        child: ElevatedButton(
          onPressed: _isStatusChangeLoading ? null : () => _showPickOptionsDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, size: 20),
              const SizedBox(width: 8),
              Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Helper methods
  bool _canDeleteDocument(LoadDocument document) {
    // Only allow deletion if document's driverId matches current session driverId
    return document.driverId == _driverId;
  }

  List<Widget> _buildGroupedDocuments(bool isCompact, bool isCupertino) {
    List<Widget> widgets = [];

    // Sort documents by updated date (most recent first)
    final sortedBolDocs = List<LoadDocument>.from(_load?.bolDocuments ?? [])
      ..sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

    final sortedPodDocs = List<LoadDocument>.from(_load?.podDocuments ?? [])
      ..sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

    final sortedLoadDocs = List<LoadDocument>.from(_load?.loadDocuments ?? [])
      ..sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

    // BOL Documents Group
    if (sortedBolDocs.isNotEmpty) {
      widgets.addAll(sortedBolDocs
          .map(
              (doc) => isCupertino ? _buildCupertinoDocumentItem(doc, isCompact, 'BOL') : _buildMaterialDocumentItem(doc, isCompact, 'BOL'))
          .toList());
    }

    // POD Documents Group
    if (sortedPodDocs.isNotEmpty) {
      widgets.addAll(sortedPodDocs
          .map(
              (doc) => isCupertino ? _buildCupertinoDocumentItem(doc, isCompact, 'POD') : _buildMaterialDocumentItem(doc, isCompact, 'POD'))
          .toList());
    }

    // Load Documents Group
    if (sortedLoadDocs.isNotEmpty) {
      widgets.addAll(sortedLoadDocs
          .map((doc) => isCupertino
              ? _buildCupertinoDocumentItem(doc, isCompact, 'Document')
              : _buildMaterialDocumentItem(doc, isCompact, 'Document'))
          .toList());
    }

    return widgets;
  }

  Future<void> _deleteDocument(String documentId) async {
    // Find the document to check permissions and determine document type
    LoadDocument? docToDelete;
    bool isPod = false;
    bool isBol = false;

    // Search for the document in all document lists and identify type
    for (var doc in _load!.loadDocuments) {
      if (doc.id == documentId) {
        docToDelete = doc;
        break;
      }
    }
    if (docToDelete == null) {
      for (var doc in _load!.podDocuments) {
        if (doc.id == documentId) {
          docToDelete = doc;
          isPod = true;
          break;
        }
      }
    }
    if (docToDelete == null) {
      for (var doc in _load!.bolDocuments) {
        if (doc.id == documentId) {
          docToDelete = doc;
          isBol = true;
          break;
        }
      }
    }

    // Check if user can delete this document
    if (docToDelete == null || !_canDeleteDocument(docToDelete)) {
      _showSnackBar('You can only delete documents you uploaded', isError: true);
      return;
    }

    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        _deletingDocuments.add(documentId);
      });

      try {
        // Build query based on document type
        Map<String, dynamic> query = {
          'driverId': _driverId,
        };

        // Add document type specific parameters
        if (isPod) {
          query['isPod'] = true;
        } else if (isBol) {
          query['isBol'] = true;
        }
        // For regular documents, we don't need additional flags

        await Loads.deleteLoadDocumentFromLoad(_load!.id, documentId, query: query);
        await _refreshAssignmentDataSilently();
        _showSnackBar('Document deleted successfully', isError: false);
      } catch (e) {
        _showSnackBar('Error deleting document: $e', isError: true);
      }

      setState(() {
        _deletingDocuments.remove(documentId);
      });
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete Document'),
              content: const Text('Are you sure you want to delete this document?'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Document'),
              content: const Text('Are you sure you want to delete this document?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  Future<bool> _showBeginWorkConfirmation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Begin Work'),
              content: const Text('Are you ready to start this assignment? This will mark the assignment as in progress.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: const Text('Begin Work'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Begin Work'),
              content: const Text('Are you ready to start this assignment? This will mark the assignment as in progress.'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Begin Work'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  Future<bool> _showCompleteWorkConfirmation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Complete Work'),
              content: const Text('Have you finished this assignment? This will mark the assignment as completed.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: const Text('Complete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Complete Work'),
              content: const Text('Have you finished this assignment? This will mark the assignment as completed.'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Complete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  Future<bool> _showStopWorkConfirmation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Stop Work'),
              content: const Text('Are you sure you want to stop working on this assignment? This will mark it as assigned again.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: const Text('Stop Work'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stop Work'),
              content: const Text('Are you sure you want to stop working on this assignment? This will mark it as assigned again.'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Stop Work'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  // Helper method for status changes without additional confirmation
  Future<void> _beginWorkWithoutConfirm() {
    return _updateRouteLegStatus(RouteLegStatus.IN_PROGRESS);
  }

  Widget _buildErrorView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      color: AppThemes.getBackgroundColor(context),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 24 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
                size: isCompact ? 48 : 56,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Assignment',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchAssignmentDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemes.getSecondaryTextColor(context),
                  foregroundColor: AppThemes.getCardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 24 : 32,
                    vertical: isCompact ? 12 : 16,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Image Viewer Page
class _ImageViewerPage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _ImageViewerPage({
    Key? key,
    required this.imageUrl,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppThemes.getPrimaryTextColor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppThemes.getCardColor(context),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemes.getBackgroundColor(context).withOpacity(0.8),
                AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.5),
                AppThemes.getBackgroundColor(context).withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppThemes.getCardColor(context),
                    AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.8),
                  ],
                ),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppThemes.getCardColor(context),
                                AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemes.getBorderColor(context).withOpacity(0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: CupertinoActivityIndicator(
                              radius: 20,
                              color: AppThemes.getSecondaryTextColor(context),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppThemes.getCardColor(context),
                                AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemes.getBorderColor(context).withOpacity(0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        CupertinoColors.systemRed.withOpacity(0.1),
                                        CupertinoColors.systemRed.withOpacity(0.05),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.systemRed.withOpacity(0.2),
                                        offset: const Offset(2, 2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    size: 32,
                                    color: CupertinoColors.systemRed,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppThemes.getSecondaryTextColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppThemes.getPrimaryTextColor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppThemes.getCardColor(context),
          foregroundColor: AppThemes.getPrimaryTextColor(context),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemes.getBackgroundColor(context),
                AppThemes.getNeumorphicBackgroundColor(context),
                AppThemes.getBackgroundColor(context),
              ],
            ),
          ),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppThemes.getCardColor(context),
                    AppThemes.getNeumorphicBackgroundColor(context),
                  ],
                ),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppThemes.getCardColor(context),
                                AppThemes.getNeumorphicBackgroundColor(context),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemes.getBorderColor(context).withOpacity(0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppThemes.getSecondaryTextColor(context),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppThemes.getCardColor(context),
                                AppThemes.getNeumorphicBackgroundColor(context),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemes.getBorderColor(context).withOpacity(0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFFEF4444).withOpacity(0.1),
                                        const Color(0xFFEF4444).withOpacity(0.05),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withOpacity(0.2),
                                        offset: const Offset(2, 2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 32,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppThemes.getSecondaryTextColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

// PDF Viewer Page
class _PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const _PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppThemes.getPrimaryTextColor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppThemes.getCardColor(context),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.share,
              color: AppThemes.getPrimaryTextColor(context),
            ),
            onPressed: () => _openExternally(context),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemes.getBackgroundColor(context).withOpacity(0.8),
                AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.5),
                AppThemes.getBackgroundColor(context).withOpacity(0.8),
              ],
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              color: AppThemes.getPrimaryTextColor(context),
              decoration: TextDecoration.none,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Neumorphic icon container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppThemes.getCardColor(context),
                              AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.8),
                            ],
                          ),
                          boxShadow: AppThemes.getNeumorphicShadows(context),
                        ),
                        child: Icon(
                          CupertinoIcons.doc_text,
                          size: 48,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Neumorphic content container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppThemes.getCardColor(context),
                              AppThemes.getNeumorphicBackgroundColor(context).withOpacity(0.8),
                            ],
                          ),
                          boxShadow: AppThemes.getNeumorphicShadows(context, isPressed: true),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PDF Document',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppThemes.getPrimaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppThemes.getSecondaryTextColor(context),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Neumorphic button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CupertinoColors.systemBlue.withOpacity(0.9),
                              CupertinoColors.systemBlue.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            // Button depth shadow
                            BoxShadow(
                              color: CupertinoColors.systemBlue.withOpacity(0.3),
                              offset: const Offset(0, 6),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                            // Light edge highlight
                            BoxShadow(
                              color: CupertinoColors.white.withOpacity(0.3),
                              offset: const Offset(-2, -2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.square_arrow_up,
                                color: CupertinoColors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Open in External App',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () => _openExternally(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppThemes.getPrimaryTextColor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppThemes.getCardColor(context),
          foregroundColor: AppThemes.getPrimaryTextColor(context),
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppThemes.getCardColor(context),
                    AppThemes.getNeumorphicBackgroundColor(context),
                  ],
                ),
                boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
                onPressed: () => _openExternally(context),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemes.getBackgroundColor(context),
                AppThemes.getNeumorphicBackgroundColor(context),
                AppThemes.getBackgroundColor(context),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Neumorphic icon container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppThemes.getCardColor(context),
                            AppThemes.getNeumorphicBackgroundColor(context),
                          ],
                        ),
                        boxShadow: AppThemes.getNeumorphicShadows(context),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Neumorphic content container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppThemes.getCardColor(context),
                            AppThemes.getNeumorphicBackgroundColor(context),
                          ],
                        ),
                        boxShadow: AppThemes.getNeumorphicShadows(context, isPressed: true),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'PDF Document',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppThemes.getPrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemes.getSecondaryTextColor(context),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Neumorphic button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                          ],
                        ),
                        boxShadow: [
                          // Button depth shadow
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            offset: const Offset(0, 6),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                          // Light edge highlight
                          BoxShadow(
                            color: const Color(0xFFFFFFFF).withOpacity(0.3),
                            offset: const Offset(-2, -2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.open_in_new, size: 18, color: Colors.white),
                        label: Text(
                          'Open in External App',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _openExternally(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openExternally(BuildContext context) async {
    try {
      final Uri url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                child: const Text('Cannot open PDF file'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              child: Text('Error opening PDF: $e'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
