import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/home_controller.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    final primaryGreen = const Color(0xFF2C8610);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.allCategories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final category = controller.allCategories[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(category),
                  selected: controller.selectedCategory == category,
                  selectedColor: primaryGreen,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: controller.selectedCategory == category
                        ? Colors.white
                        : primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    controller.setSelectedCategory(category);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
