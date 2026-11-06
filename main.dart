import 'dart:convert';
import 'dart:io';

import 'order.dart';
import 'page.dart';

final File orderFile = File('order.json');
List<Order> orders = [];

void loadOrders() {
  String jsonString = orderFile.readAsStringSync();
  List<dynamic> data = jsonDecode(jsonString);
  orders = data.map((item) => Order.fromJson(item)).toList();
}

void saveOrders(List<Order> updatedOrders) {
  String jsonString = const JsonEncoder.withIndent('  ')
      .convert(updatedOrders.map((order) => order.toJson()).toList());
  orderFile.writeAsStringSync(jsonString);
  orders = updatedOrders;
}

String? validateOrder(Map<String, String> form) {
  String item = (form['item'] ?? '').trim();
  String name = (form['itemName'] ?? '').trim();
  String currency = (form['currency'] ?? '').trim().toUpperCase();
  double? price = double.tryParse(form['price'] ?? '');
  int? quantity = int.tryParse(form['quantity'] ?? '');

  if (item.isEmpty || name.isEmpty) {
    return 'Please enter the item code and item name.';
  }
  if (orders.any((order) => order.item.toLowerCase() == item.toLowerCase())) {
    return 'This item code already exists. Please use another code.';
  }
  if (price == null || !price.isFinite || price <= 0) {
    return 'Price must be a number greater than 0.';
  }
  if (quantity == null || quantity <= 0) {
    return 'Quantity must be a whole number greater than 0.';
  }
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
    return 'Enter a three-letter currency code, for example USD.';
  }
  return null;
}

void showPage(
  HttpRequest request, {
  String search = '',
  String message = '',
  bool isError = false,
  Map<String, String> form = const {},
}) {
  List<Order> results = orders.where((order) {
    return order.itemName.toLowerCase().contains(search.toLowerCase());
  }).toList();

  request.response.headers.contentType = ContentType.html;
  request.response.write(renderPage(results, search, message, isError, form));
}

Future<void> main() async {
  loadOrders();
  int port = int.parse(Platform.environment['PORT'] ?? '8080');
  HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('My Order is running at http://localhost:$port');
  print('Press Ctrl+C to stop.');

  await for (HttpRequest request in server) {
    try {
      if (request.method == 'GET' && request.uri.path == '/style.css') {
        request.response.headers.contentType = ContentType('text', 'css');
        request.response.write(File('style.css').readAsStringSync());
      } else if (request.method == 'GET' && request.uri.path == '/') {
        showPage(
          request,
          search: (request.uri.queryParameters['search'] ?? '').trim(),
          message: request.uri.queryParameters['added'] == '1'
              ? 'Order added successfully.'
              : '',
        );
      } else if (request.method == 'POST' && request.uri.path == '/add') {
        String body = await utf8.decoder.bind(request).join();
        Map<String, String> form = Uri.splitQueryString(body);
        String? error = validateOrder(form);

        if (error != null) {
          request.response.statusCode = HttpStatus.badRequest;
          showPage(request, message: error, isError: true, form: form);
        } else {
          Order order = Order(
            item: form['item']!.trim(),
            itemName: form['itemName']!.trim(),
            price: double.parse(form['price']!),
            currency: form['currency']!.trim().toUpperCase(),
            quantity: int.parse(form['quantity']!),
          );
          saveOrders([...orders, order]);
          request.response.statusCode = HttpStatus.seeOther;
          request.response.headers.set(HttpHeaders.locationHeader, '/?added=1');
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Page not found.');
      }
    } catch (error) {
      stderr.writeln(error);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<h1>Unable to process the order</h1>'
        '<p>Please check that order.json is available and writable.</p>'
        '<a href="/">Back to My Order</a>',
      );
    } finally {
      await request.response.close();
    }
  }
}
