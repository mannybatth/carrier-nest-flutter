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
}

class LoadStop {
  final String id;
  final DateTime createdAt;
  final String userId;
  final LoadStopType type;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;
  final DateTime date;
  final String time;

  LoadStop({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.type,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.date,
    required this.time,
  });
  LoadStop.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        userId = json['userId'],
        type = LoadStopType.values[json['type']],
        name = json['name'],
        street = json['street'],
        city = json['city'],
        state = json['state'],
        zip = json['zip'],
        country = json['country'],
        date = DateTime.parse(json['date']),
        time = json['time'];
}

class Customer {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? contactEmail;
  final String? billingEmail;
  final String? paymentStatusEmail;

  Customer({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.contactEmail,
    this.billingEmail,
    this.paymentStatusEmail,
  });
  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        name = json['name'],
        contactEmail = json['contactEmail'],
        billingEmail = json['billingEmail'],
        paymentStatusEmail = json['paymentStatusEmail'];
}

class Carrier {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final String name;

  Carrier({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.name,
  });
  Carrier.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        email = json['email'],
        name = json['name'];
}

class Driver {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? email;
  final String? phone;

  Driver({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.email,
    this.phone,
  });
  Driver.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        name = json['name'],
        email = json['email'],
        phone = json['phone'];
}

class LoadDocument {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileKey;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;

  LoadDocument({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.fileKey,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });
  LoadDocument.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
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

  LoadActivity({
    required this.id,
    required this.createdAt,
    required this.loadId,
    required this.action,
  });
}

class Invoice {
  final String id;
  final String userId;
  final String carrierId;
  final String loadId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int invoiceNum;
  final InvoiceStatus status;
  final double totalAmount;
  final double remainingAmount;
  final DateTime invoicedAt;
  final DateTime dueDate;
  final int dueNetDays;

  Invoice({
    required this.id,
    required this.userId,
    required this.carrierId,
    required this.loadId,
    required this.createdAt,
    required this.updatedAt,
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
        userId = json['userId'],
        carrierId = json['carrierId'],
        loadId = json['loadId'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        invoiceNum = json['invoiceNum'],
        status = InvoiceStatus.values[json['status']],
        totalAmount = json['totalAmount'].toDouble(),
        remainingAmount = json['remainingAmount'].toDouble(),
        invoicedAt = DateTime.parse(json['invoicedAt']),
        dueDate = DateTime.parse(json['dueDate']),
        dueNetDays = json['dueNetDays'];
}

class ExpandedLoad {
  final String id;
  final String userId;
  final String customerId;
  final String carrierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String refNum;
  final String shipperId;
  final String receiverId;
  final double rate;
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
  final LoadDocument rateconDocument;
  final List<LoadDocument> podDocuments;

  ExpandedLoad({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.carrierId,
    required this.createdAt,
    required this.updatedAt,
    required this.refNum,
    required this.shipperId,
    required this.receiverId,
    required this.rate,
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
    required this.rateconDocument,
    required this.podDocuments,
  });
  ExpandedLoad.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        customerId = json['customerId'],
        carrierId = json['carrierId'],
        createdAt = DateTime.parse(json['createdAt']),
        updatedAt = DateTime.parse(json['updatedAt']),
        refNum = json['refNum'],
        shipperId = json['shipperId'],
        receiverId = json['receiverId'],
        rate = json['rate'].toDouble(),
        routeEncoded = json['routeEncoded'],
        routeDistance = json['routeDistance'].toDouble(),
        routeDuration = json['routeDuration'].toDouble(),
        status = LoadStatus.values[json['status']],
        customer = Customer.fromJson(json['customer']),
        invoice =
            json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
        shipper = LoadStop.fromJson(json['shipper']),
        receiver = LoadStop.fromJson(json['receiver']),
        stops = (json['stops'] as List)
            .map((item) => LoadStop.fromJson(item))
            .toList(),
        drivers = (json['drivers'] as List)
            .map((item) => Driver.fromJson(item))
            .toList(),
        loadDocuments = (json['loadDocuments'] as List)
            .map((item) => LoadDocument.fromJson(item))
            .toList(),
        rateconDocument = LoadDocument.fromJson(json['rateconDocument']),
        podDocuments = (json['podDocuments'] as List)
            .map((item) => LoadDocument.fromJson(item))
            .toList();
}
