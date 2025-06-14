import 'package:smart/models/seller_content.dart';

final List<SellerContent> sellerContents = [
  SellerContent(
    id: '1',
    title: 'Promo Makan Siang Hemat',
    description: 'Dapatkan diskon 20% untuk paket makan siang',
    imageUrl:
        "https://res.cloudinary.com/de2bfha4g/image/upload/v1749553578/products/iLaExNtKBRegpLv2maXYWyDuFQ43/rhgjhu1c0avvtli4osoj.jpg",
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    status: 'Published',
  ),
  SellerContent(
    id: '2',
    title: 'Menu Baru: Nasi Goreng Spesial',
    description: 'Mencoba resep baru dengan bumbu rahasia',
    imageUrl:
        'https://res.cloudinary.com/de2bfha4g/image/upload/v1749553578/products/iLaExNtKBRegpLv2maXYWyDuFQ43/rhgjhu1c0avvtli4osoj.jpg',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    status: 'Published',
  ),
  SellerContent(
    id: '3',
    title: 'Tips Makan Sehat',
    description: 'Bagaimana memilih makanan sehat untuk keluarga',
    imageUrl:
        'https://res.cloudinary.com/de2bfha4g/image/upload/v1749553578/products/iLaExNtKBRegpLv2maXYWyDuFQ43/rhgjhu1c0avvtli4osoj.jpg',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    status: 'Draft',
  ),
];
