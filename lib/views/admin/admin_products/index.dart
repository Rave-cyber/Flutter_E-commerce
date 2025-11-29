import 'package:firebase/controllers/admin/product_controller.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import 'form.dart';

import 'package:flutter/material.dart';
import '/models/product.dart';
import '/views/admin/admin_products/form.dart';

class AdminProductsIndex extends StatefulWidget {
  const AdminProductsIndex({Key? key}) : super(key: key);

  @override
  State<AdminProductsIndex> createState() => _AdminProductsIndexState();
}

class _AdminProductsIndexState extends State<AdminProductsIndex> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Stack(
        children: [
          StreamBuilder<List<ProductModel>>(
            stream: _productService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No products found.'));
              }

              final products = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: product.image.isNotEmpty
                          ? Image.network(
                              product.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(product.name),
                      subtitle: Text(
                          'Stock: ${product.stock_quantity} | Price: \$${product.sale_price}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminProductForm(product: product),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                      'Are you sure you want to delete "${product.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _productService.deleteProduct(product.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Floating button for creating new product
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProductForm()),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Product',
            ),
          ),
        ],
      ),
    );
  }
}
