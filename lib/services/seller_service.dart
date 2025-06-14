import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart/models/seller.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'sellers';

  // Get all sellers (including unverified) as stream
  Stream<List<SellerModel>> getAllSellers() {
    return _firestore
        .collection(_collection)
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SellerModel.fromMap(data, doc.id);
          }).toList();
        });
  }

  // Get seller by ID
  Future<SellerModel?> getSellerById(String sellerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(sellerId).get();
      if (doc.exists) {
        return SellerModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting seller: $e');
      return null;
    }
  }

  // Search sellers by name
  Future<List<SellerModel>> searchSellersByName(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isVerified', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => SellerModel.fromMap(doc.data(), doc.id))
          .where(
            (seller) =>
                seller.nameToko.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('Error searching sellers: $e');
      return [];
    }
  }

  // Get sellers by category
  Stream<List<SellerModel>> getSellersByCategory(String category) {
    Query query = _firestore
        .collection(_collection)
        .where('isVerified', isEqualTo: true);

    if (category != 'Semua') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SellerModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Get top rated sellers
  Future<List<SellerModel>> getTopRatedSellers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SellerModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting top rated sellers: $e');
      return [];
    }
  }

  // Get popular sellers (based on total products)
  Future<List<SellerModel>> getPopularSellers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isVerified', isEqualTo: true)
          .orderBy('totalProducts', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SellerModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting popular sellers: $e');
      return [];
    }
  }

  // Update seller rating
  Future<void> updateSellerRating(String sellerId, double newRating) async {
    try {
      await _firestore.collection(_collection).doc(sellerId).update({
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating seller rating: $e');
      rethrow;
    }
  }

  // Increment total products count
  Future<void> incrementTotalProducts(String sellerId) async {
    try {
      await _firestore.collection(_collection).doc(sellerId).update({
        'totalProducts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing total products: $e');
      rethrow;
    }
  }

  // Decrement total products count
  Future<void> decrementTotalProducts(String sellerId) async {
    try {
      await _firestore.collection(_collection).doc(sellerId).update({
        'totalProducts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error decrementing total products: $e');
      rethrow;
    }
  }
}
