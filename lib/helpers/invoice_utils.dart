import 'package:carrier_nest_flutter/models.dart';

final List<Map<String, dynamic>> invoiceTermOptions = [
  {
    'value': 0,
    'label': 'Due on Receipt',
  },
  {
    'value': 15,
    'label': 'Net 15 days',
  },
  {
    'value': 30,
    'label': 'Net 30 days',
  },
  {
    'value': 45,
    'label': 'Net 45 days',
  },
];

UIInvoiceStatus invoiceStatus(Invoice invoice) {
  if (invoice.status == InvoiceStatus.PAID) {
    return UIInvoiceStatus.PAID;
  }

  if (invoice.dueNetDays > 0) {
    final DateTime now = DateTime.now();
    if (now.isAfter(invoice.dueDate!)) {
      return UIInvoiceStatus.OVERDUE;
    }
  }

  if (invoice.status == InvoiceStatus.PARTIALLY_PAID) {
    return UIInvoiceStatus.PARTIALLY_PAID;
  }

  return UIInvoiceStatus.NOT_PAID;
}
