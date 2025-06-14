// lib/managers/content_interaction_manager.dart
import 'package:smart/models/edukasi.dart';
import 'package:smart/services/edukasi_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class ContentInteractionManager {
  final EdukasiService _edukasiService = EdukasiService();

  // Singleton pattern
  static final ContentInteractionManager _instance =
      ContentInteractionManager._internal();
  factory ContentInteractionManager() => _instance;
  ContentInteractionManager._internal();

  /// Handle views update for content
  Future<bool> updateContentViews({
    required String contentId,
    required int newViewsCount,
    BuildContext? context,
  }) async {
    try {
      await _edukasiService.updateViews(contentId, newViewsCount);
      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui views: $e',
        );
      }
      return false;
    }
  }

  /// Handle likes update with Firebase user tracking
  Future<bool> updateContentLikes({
    required String contentId,
    required int newLikesCount,
    required bool isLiked,
    required String userId,
    BuildContext? context,
  }) async {
    try {
      // Update likes in Firebase
      await _edukasiService.updateLikes(contentId, newLikesCount);

      // Update user like status in Firebase
      await _edukasiService.setUserLikeStatus(contentId, userId, isLiked);

      print(
        '✅ Updated like status: $contentId -> $isLiked (Total likes: $newLikesCount)',
      );
      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui likes: $e',
        );
      }
      return false;
    }
  }

  /// Get user's liked content IDs
  Future<Set<String>> getUserLikedContentIds(String userId) async {
    try {
      final likedContentIds = await _edukasiService.getUserLikedContentIds(
        userId,
      );
      print(
        '✅ Loaded ${likedContentIds.length} liked contents for user: $userId',
      );
      return likedContentIds.toSet();
    } catch (e) {
      print('⚠️ Error loading user liked content: $e');
      return <String>{};
    }
  }

  /// Update local content data in lists
  void updateLocalContentData({
    required String contentId,
    required List<EdukasiModel> allContent,
    required List<EdukasiModel> filteredContent,
    int? newViewsCount,
    int? newLikesCount,
  }) {
    // Update in filtered list
    final filteredIndex = filteredContent.indexWhere(
      (content) => content.id == contentId,
    );
    if (filteredIndex != -1) {
      if (newViewsCount != null) {
        filteredContent[filteredIndex].views = newViewsCount;
      }
      if (newLikesCount != null) {
        filteredContent[filteredIndex].likes = newLikesCount;
      }
    }

    // Update in all content list
    final allIndex = allContent.indexWhere(
      (content) => content.id == contentId,
    );
    if (allIndex != -1) {
      if (newViewsCount != null) {
        allContent[allIndex].views = newViewsCount;
      }
      if (newLikesCount != null) {
        allContent[allIndex].likes = newLikesCount;
      }
    }
  }

  /// Update liked content IDs set
  void updateLikedContentIds({
    required Set<String> likedContentIds,
    required String contentId,
    required bool isLiked,
  }) {
    if (isLiked) {
      likedContentIds.add(contentId);
    } else {
      likedContentIds.remove(contentId);
    }
  }
}
