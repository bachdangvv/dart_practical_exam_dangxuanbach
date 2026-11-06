import 'dart:convert';

import 'order.dart';

String escape(String value) => const HtmlEscape().convert(value);

String renderPage(
  List<Order> orders,
  String search,
  String message,
  bool isError,
  Map<String, String> form,
) {
  String rows = '';
  for (int i = 0; i < orders.length; i++) {
    Order order = orders[i];
    rows +=
        '''
      <tr>
        <td>${i + 1}</td>
        <td>${escape(order.item)}</td>
        <td>${escape(order.itemName)}</td>
        <td class="number">${order.quantity}</td>
        <td class="number">${order.price.toStringAsFixed(2)}</td>
        <td>${escape(order.currency)}</td>
      </tr>
    ''';
  }

  if (orders.isEmpty) {
    rows = '<tr><td colspan="6" class="empty">No orders found.</td></tr>';
  }

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Order</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>My Order</h1>
    ${message.isEmpty ? '' : '<p role="alert" class="message ${isError ? 'error' : 'success'}">${escape(message)}</p>'}

    <form action="/add" method="post" class="order-form">
      <div class="field">
        <label for="item">Item</label>
        <input id="item" name="item" placeholder="A1002" required
          value="${escape(form['item'] ?? '')}">
      </div>
      <div class="field">
        <label for="itemName">Item Name</label>
        <input id="itemName" name="itemName" placeholder="Item name" required
          value="${escape(form['itemName'] ?? '')}">
      </div>
      <div class="field">
        <label for="price">Price</label>
        <input id="price" name="price" type="number" min="0.01" step="0.01"
          placeholder="Price" required value="${escape(form['price'] ?? '')}">
      </div>
      <div class="quantity-currency">
        <div class="field">
          <label for="quantity">Quantity</label>
          <input id="quantity" name="quantity" type="number" min="1" step="1"
            required value="${escape(form['quantity'] ?? '1')}">
        </div>
        <div class="field">
          <label for="currency">Currency</label>
          <input id="currency" name="currency" maxlength="3" pattern="[A-Za-z]{3}"
            required value="${escape(form['currency'] ?? 'USD')}">
        </div>
      </div>
      <div class="form-actions">
        <button type="submit">Add Item to Cart</button>
      </div>
    </form>

    <section aria-labelledby="orders-title">
      <div class="list-heading">
        <h2 id="orders-title">Order List</h2>
        <span>${orders.length} order${orders.length == 1 ? '' : 's'}</span>
      </div>
      <form action="/" method="get" class="search-form">
        <label for="search">Search by Item Name</label>
        <div class="search-controls">
          <input id="search" name="search" placeholder="Enter item name"
            value="${escape(search)}">
          <button type="submit">Search</button>
          <a href="/">Show all</a>
        </div>
      </form>
      <div class="table-wrapper">
        <table>
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Item</th>
              <th scope="col">Item Name</th>
              <th scope="col" class="number">Quantity</th>
              <th scope="col" class="number">Price</th>
              <th scope="col">Currency</th>
            </tr>
          </thead>
          <tbody>$rows</tbody>
        </table>
      </div>
    </section>
  </main>
</body>
</html>
''';
}
