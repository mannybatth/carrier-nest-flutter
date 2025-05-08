import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/helpers/invoice_utils.dart';

bool isDate24HrInThePast(DateTime date) {
  DateTime now = DateTime.now();
  Duration diff = now.difference(date);
  return diff.inHours > 24;
}

UILoadStatus loadStatusToUIStatus(LoadStatus status) {
  switch (status) {
    case LoadStatus.CREATED:
      return UILoadStatus.booked;
    case LoadStatus.IN_PROGRESS:
      return UILoadStatus.inProgress;
    case LoadStatus.DELIVERED:
      return UILoadStatus.delivered;
    case LoadStatus.POD_READY:
      return UILoadStatus.podReady;
    default:
      return UILoadStatus.booked;
  }
}

UILoadStatus loadStatus(ExpandedLoad load) {
  // Assuming invoiceStatus function and UIInvoiceStatus enum are defined elsewhere
  /* if (load.invoice != null) {
    UIInvoiceStatus inStatus = invoiceStatus(load.invoice!);
    switch (inStatus) {
      case UIInvoiceStatus.NOT_PAID:
        return UILoadStatus.invoiced;
      case UIInvoiceStatus.OVERDUE:
        return UILoadStatus.overdue;
      case UIInvoiceStatus.PARTIALLY_PAID:
        return UILoadStatus.partiallyPaid;
      case UIInvoiceStatus.PAID:
        return UILoadStatus.paid;
      default:
        break;
    }
  } */
  if (load.invoice?.id != null) {
    return UILoadStatus.invoiced;
  }

  if (load.podDocuments.isNotEmpty) {
    return UILoadStatus.podReady;
  }

  if (load.status == LoadStatus.DELIVERED) {
    return UILoadStatus.delivered;
  }

  if (load.status == LoadStatus.IN_PROGRESS) {
    return UILoadStatus.inProgress;
  }

  return UILoadStatus.booked;
}
