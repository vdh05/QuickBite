class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String imageUrl;
  final double rating;
  final int deliveryTime;
  final double distance;
  final int costForTwo;
  
  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.distance,
    required this.costForTwo,
  });
  
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    try {
      return Restaurant(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Restaurant',
        cuisine: json['cuisine']?.toString() ?? 'Various',
        imageUrl: json['imageUrl']?.toString() ?? 'https://via.placeholder.com/400x300?text=No+Image',
        rating: (json['rating'] is num) 
            ? (json['rating'] as num).toDouble() 
            : 0.0,
        deliveryTime: (json['deliveryTime'] is num) 
            ? (json['deliveryTime'] as num).toInt() 
            : 30,
        distance: (json['distance'] is num) 
            ? (json['distance'] as num).toDouble() 
            : 0.0,
        costForTwo: (json['costForTwo'] is num) 
            ? (json['costForTwo'] as num).toInt() 
            : 0,
      );
    } catch (e) {
      print('Error parsing restaurant: $e');
      print('JSON data: $json');
      return Restaurant(
        id: '',
        name: 'Error Restaurant',
        cuisine: 'Error',
        imageUrl: 'https://via.placeholder.com/400x300?text=Error',
        rating: 0.0,
        deliveryTime: 0,
        distance: 0.0,
        costForTwo: 0,
      );
    }
  }
}

// Sample restaurant data
final List<Restaurant> restaurants = [
  Restaurant(
    id: '1',
    name: 'The Burger Company',
    cuisine: 'American, Fast Food, Burgers',
    imageUrl: 'https://res.cloudinary.com/swiggy/image/upload/fl_lossy,f_auto,q_auto,w_508,h_320,c_fill/xbcxtblwjrsbc8ek36yj',
    rating: 4.2,
    deliveryTime: 25,
    distance: 1.5,
    costForTwo: 300,
  ),
  Restaurant(
    id: '2',
    name: 'Paradise Biryani',
    cuisine: 'Biryani, North Indian, Kebabs',
    imageUrl: 'https://res.cloudinary.com/swiggy/image/upload/fl_lossy,f_auto,q_auto,w_508,h_320,c_fill/cvohlrqzborrnkqydvvt',
    rating: 4.5,
    deliveryTime: 30,
    distance: 2.0,
    costForTwo: 400,
  ),
  Restaurant(
    id: '3',
    name: 'Pizza Hub',
    cuisine: 'Italian, Pizzas, Fast Food',
    imageUrl: 'https://res.cloudinary.com/swiggy/image/upload/fl_lossy,f_auto,q_auto,w_508,h_320,c_fill/uyiashxmda6kdpjheobp',
    rating: 4.1,
    deliveryTime: 35,
    distance: 2.5,
    costForTwo: 450,
  ),
  Restaurant(
    id: '4',
    name: 'Chai Point',
    cuisine: 'Beverages, Snacks, Breakfast',
    imageUrl: 'https://res.cloudinary.com/swiggy/image/upload/fl_lossy,f_auto,q_auto,w_508,h_320,c_fill/nit5ubr4mwzueoox9m89',
    rating: 3.9,
    deliveryTime: 20,
    distance: 1.0,
    costForTwo: 200,
  ),
];
