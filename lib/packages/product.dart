class Product {
  final String name;
  final List<String> subCategories;

  Product({
    required this.name,
    required this.subCategories,
  });
}

final Product restaurantProduct = Product(
  name: 'restaurant',
  subCategories: [
    '식당',
    '밥',
    '음식',
    '가게',
  ],
);

final Product cafeProduct = Product(
  name: 'cafe',
  subCategories: [
    '카페',
    '커피',
    '차',
    '음료',
  ],
);

final Product parkProduct = Product(
  name: 'park',
  subCategories: [
    '공원',
    '산책로',
    '자연',
    '숲',
  ],
);

final Product playProduct = Product(
  name: 'play',
  subCategories: [
    '아트홀',
    '축제',
    '공연',
  ],
);

final Product shoppingProduct = Product(
  name: 'mall',
  subCategories: [
    '백화점',
    '쇼핑몰',
    '상점',
    '쇼핑',
    '마트',
  ],
);

final Product displayProduct = Product(
  name: 'display',
  subCategories: [
    '뮤지움',
    '미술관',
    '박물관',
    '전시',
    '갤러리',
    '아트',
    '뮤지엄',
  ],
);
