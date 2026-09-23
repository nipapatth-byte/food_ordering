import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';

class MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onAddToCart;

  const MenuCard({super.key, required this.item, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFFFE9E9),
                      child: const Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFFFE9E9),
                    child: const Icon(
                      Icons.fastfood,
                      size: 40,
                      color: Color(0xFFC62828),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(0)} บาท',
                      style: const TextStyle(
                        color: Color(0xFFFF4D26),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Material(
                      color: const Color(0xFFFF4D26),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onAddToCart,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.add, color: Colors.white, size: 19),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
