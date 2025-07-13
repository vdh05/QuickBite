class FoodCategory {
  final String name;
  final String imageUrl;

  FoodCategory({required this.name, required this.imageUrl});
}

// Sample food categories data
final List<FoodCategory> foodCategories = [
  FoodCategory(
    name: 'Biryani',
    imageUrl: 'http://t4.ftcdn.net/jpg/04/36/36/57/360_F_436365754_z3i5Es0sFmZuLY6GZIzdiU01v9HqpGZe.jpg',
    ),
  FoodCategory(
    name: 'Pizza',
    imageUrl: 'https://b.zmtcdn.com/data/pictures/7/20832837/d62510a70ac943994cdca3113a732c20_o2_featured_v2.jpg',
  ),
  FoodCategory(
    name: 'Burger',
    imageUrl: 'https://b.zmtcdn.com/data/pictures/7/20832837/d62510a70ac943994cdca3113a732c20_o2_featured_v2.jpg',
  ),
  FoodCategory(
    name: 'Chinese',
    imageUrl: 'https://b.zmtcdn.com/data/pictures/7/20832837/d62510a70ac943994cdca3113a732c20_o2_featured_v2.jpg',
  ),
  FoodCategory(
    name: 'Desserts',
    imageUrl: 'https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.cubesnjuliennes.com%2Fchicken-biryani-recipe%2F&psig=AOvVaw3uEQf77fNQQ7fWm-nzvgVP&ust=1748689388913000&source=images&cd=vfe&opi=89978449&ved=0CBQQjRxqFwoTCICBxOCFy40DFQAAAAAdAAAAABAK',
  ),
  FoodCategory(
    name: 'South Indian',
    imageUrl: 'https://b.zmtcdn.com/data/pictures/7/20832837/d62510a70ac943994cdca3113a732c20_o2_featured_v2.jpg',
  ),
];
