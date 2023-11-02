enum LoadStopType {
  SHIPPER,
  RECEIVER,
  STOP,
}

enum LoadStatus {
  CREATED,
  IN_PROGRESS,
  DELIVERED,
  POD_READY,
}

enum InvoiceStatus {
  NOT_PAID,
  PARTIALLY_PAID,
  PAID,
}

enum LoadActivityAction {
  CHANGE_STATUS,
  UPLOAD_POD,
  REMOVE_POD,
  UPLOAD_DOCUMENT,
  REMOVE_DOCUMENT,
  ASSIGN_DRIVER,
  UNASSIGN_DRIVER,
}

enum UILoadStatus {
  booked, // load created but not yet set as in progress
  inProgress, // load marked as in progress
  delivered, // load delivered to last drop off and awaiting POD docs
  podReady, // POD is uploaded by the driver
  invoiced, // invoice is created
  partiallyPaid, // incomplete full payment
  paid, // full payment received for invoice
  overdue, // invoice past due date
}

enum UIInvoiceStatus {
  NOT_PAID,
  PARTIALLY_PAID,
  OVERDUE,
  PAID,
}

class Load {
  final String id;
  final String userId;
  final String? customerId;
  final String carrierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String refNum;
  final String shipperId;
  final String receiverId;
  final double rate;
  final String? routeEncoded;
  final double? routeDistance;
  final double? routeDuration;
  final LoadStatus status;

  Load({
    required this.id,
    required this.userId,
    this.customerId,
    required this.carrierId,
    required this.createdAt,
    required this.updatedAt,
    required this.refNum,
    required this.shipperId,
    required this.receiverId,
    required this.rate,
    this.routeEncoded,
    this.routeDistance,
    this.routeDuration,
    required this.status,
  });
  Load.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        customerId = json['customerId'] as String?,
        carrierId = json['carrierId'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        refNum = json['refNum'],
        shipperId = json['shipperId'],
        receiverId = json['receiverId'],
        rate = double.parse(json['rate'].toString()),
        routeEncoded = json['routeEncoded'] as String?,
        routeDistance = json['routeDistance'] != null
            ? double.parse(json['routeDistance'].toString())
            : null,
        routeDuration = json['routeDuration'] != null
            ? double.parse(json['routeDuration'].toString())
            : null,
        status = LoadStatus.values.byName(json['status']);
}

class LoadStop {
  final String id;
  final DateTime? createdAt;
  final String? userId;
  final LoadStopType type;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;
  final DateTime date;
  final String time;
  final double? latitude;
  final double? longitude;
  final String? poNumbers;
  final String? pickUpNumbers;
  final String? referenceNumbers;

  LoadStop({
    required this.id,
    this.createdAt,
    this.userId,
    required this.type,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.date,
    required this.time,
    this.latitude,
    this.longitude,
    this.poNumbers,
    this.pickUpNumbers,
    this.referenceNumbers,
  });

  LoadStop.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        userId = json['userId'],
        type = LoadStopType.values.byName(json['type']),
        name = json['name'],
        street = json['street'],
        city = json['city'],
        state = json['state'],
        zip = json['zip'],
        country = json['country'],
        date = DateTime.parse(json['date']),
        time = json['time'],
        latitude = json['latitude']?.toDouble(),
        longitude = json['longitude']?.toDouble(),
        poNumbers = json['poNumbers']?.replaceAll('\n', '') ?? '',
        pickUpNumbers = json['pickUpNumbers']?.replaceAll('\n', '') ?? '',
        referenceNumbers = json['referenceNumbers']?.replaceAll('\n', '') ?? '';
}

class Customer {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? contactEmail;
  final String? billingEmail;
  final String? paymentStatusEmail;

  Customer({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.contactEmail,
    this.billingEmail,
    this.paymentStatusEmail,
  });
  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        name = json['name'],
        contactEmail = json['contactEmail'],
        billingEmail = json['billingEmail'],
        paymentStatusEmail = json['paymentStatusEmail'];
}

class Carrier {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String email;
  final String name;

  Carrier({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.email,
    required this.name,
  });
  Carrier.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        email = json['email'],
        name = json['name'];
}

class Driver {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String? email;
  final String? phone;

  Driver({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.name,
    this.email,
    this.phone,
  });
  Driver.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        name = json['name'],
        email = json['email'],
        phone = json['phone'];
}

class LoadDocument {
  final String id;
  final String? driverId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String fileKey;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;

  LoadDocument({
    required this.id,
    required this.driverId,
    this.createdAt,
    this.updatedAt,
    required this.fileKey,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });
  LoadDocument.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        driverId = json['driverId'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        fileKey = json['fileKey'],
        fileUrl = json['fileUrl'],
        fileName = json['fileName'],
        fileType = json['fileType'],
        fileSize = json['fileSize'];
}

class LoadActivity {
  final String id;
  final DateTime createdAt;
  final String loadId;
  final LoadActivityAction action;
  final double? latitude;
  final double? longitude;

  LoadActivity({
    required this.id,
    required this.createdAt,
    required this.loadId,
    required this.action,
    this.latitude,
    this.longitude,
  });

  LoadActivity.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        loadId = json['loadId'],
        action = LoadActivityAction.values.byName(json['action']),
        latitude = json['latitude']?.toDouble(),
        longitude = json['longitude']?.toDouble();
}

class Invoice {
  final String id;
  final String? userId;
  final String? carrierId;
  final String? loadId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int invoiceNum;
  final InvoiceStatus status;
  final double totalAmount;
  final double remainingAmount;
  final DateTime? invoicedAt;
  final DateTime? dueDate;
  final int dueNetDays;

  Invoice({
    required this.id,
    this.userId,
    this.carrierId,
    this.loadId,
    this.createdAt,
    this.updatedAt,
    required this.invoiceNum,
    required this.status,
    required this.totalAmount,
    required this.remainingAmount,
    required this.invoicedAt,
    required this.dueDate,
    required this.dueNetDays,
  });
  Invoice.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'] as String?,
        carrierId = json['carrierId'] as String?,
        loadId = json['loadId'] as String?,
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        invoiceNum = json['invoiceNum'],
        status = InvoiceStatus.values.byName(json['status']),
        totalAmount = json['totalAmount'] != null
            ? double.parse(json['totalAmount'].toString())
            : 0.0,
        remainingAmount = json['remainingAmount'] != null
            ? double.parse(json['remainingAmount'].toString())
            : 0.0,
        invoicedAt = json['invoicedAt'] != null
            ? DateTime.parse(json['invoicedAt'])
            : null, // Adjusted here
        dueDate = json['dueDate'] != null
            ? DateTime.parse(json['dueDate'])
            : null, // Adjusted here
        dueNetDays = json['dueNetDays'];
}

class ExpandedLoad {
  final String id;
  final String userId;
  final String customerId;
  final String carrierId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String refNum;
  final String shipperId;
  final String receiverId;
  final String routeEncoded;
  final double routeDistance;
  final double routeDuration;
  final LoadStatus status;
  final Customer customer;
  final Invoice? invoice;
  final LoadStop shipper;
  final LoadStop receiver;
  final List<LoadStop> stops;
  final List<Driver> drivers;
  final List<LoadDocument> loadDocuments;
  final LoadDocument? rateconDocument;
  final List<LoadDocument> podDocuments;

  ExpandedLoad({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.carrierId,
    this.createdAt,
    this.updatedAt,
    required this.refNum,
    required this.shipperId,
    required this.receiverId,
    required this.routeEncoded,
    required this.routeDistance,
    required this.routeDuration,
    required this.status,
    required this.customer,
    this.invoice,
    required this.shipper,
    required this.receiver,
    required this.stops,
    required this.drivers,
    required this.loadDocuments,
    this.rateconDocument,
    required this.podDocuments,
  });
  ExpandedLoad.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        customerId = json['customerId'],
        carrierId = json['carrierId'],
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        refNum = json['refNum'],
        shipperId = json['shipperId'],
        receiverId = json['receiverId'],
        routeEncoded = json['routeEncoded'],
        routeDistance = json['routeDistance'] != null
            ? double.parse(json['routeDistance'].toString())
            : 0.0,
        routeDuration = json['routeDuration'] != null
            ? double.parse(json['routeDuration'].toString())
            : 0.0,
        status = LoadStatus.values.byName(json['status']),
        customer = Customer.fromJson(json['customer']),
        invoice =
            json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
        shipper = LoadStop.fromJson(json['shipper']),
        receiver = LoadStop.fromJson(json['receiver']),
        stops = (json['stops'] as List? ?? [])
            .map((item) => LoadStop.fromJson(item))
            .toList(),
        drivers = (json['drivers'] as List? ?? [])
            .map((item) => Driver.fromJson(item))
            .toList(),
        loadDocuments = (json['loadDocuments'] as List? ?? [])
            .map((item) => LoadDocument.fromJson(item))
            .toList(),
        rateconDocument = json['rateconDocument'] != null
            ? LoadDocument.fromJson(json['rateconDocument'])
            : null,
        podDocuments = (json['podDocuments'] as List? ?? [])
            .map((item) => LoadDocument.fromJson(item))
            .toList();
}
