import 'dart:convert';
import 'dart:io';
import 'package:either_dart/either.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_crud_app/core/utils/logger.dart'; // Your logger
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart'; // Needed for direct storage access
import 'package:share_plus/share_plus.dart';

import '../../data/models/task_model.dart';
import '../errors/failures.dart'; // Your Failure classes

// Define specific failure types if not already in core/errors/failures.dart
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

class GenericFailure extends Failure { // Renamed from DataTransferFailure to be more general
  const GenericFailure(String message) : super(message);
}


class DataTransferService {
  static const String _exportFileName = 'tasks_export.json';

  Future<Either<Failure, String>> exportTasks(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return Left(GenericFailure('No tasks to export.'));
    }

    try {
      // Permissions for share_plus are generally handled by the plugin via OS dialogs.
      // Explicit permission requests are more for direct file system writes to specific public dirs.

      final List<Map<String, dynamic>> taskJsonList = tasks.map((task) => task.toJson()).toList();
      final String jsonString = jsonEncode(taskJsonList);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$_exportFileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      appLogger.i('Tasks exported to temporary file: $filePath');

      final xFile = XFile(filePath, mimeType: 'application/json', name: _exportFileName);
      
      // Using Share.shareXFiles to bring up the native share sheet.
      // The result indicates if the share sheet was shown, not if the user completed an action.
      final result = await Share.shareXFilesWithResult([xFile], subject: 'My Tasks Export');

      if (result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed) {
        // Dismissed also means the share sheet was shown.
        // It's hard to confirm actual save from share sheet.
         return Right('Tasks prepared. Use the share dialog to save or send.');
      } else {
        appLogger.w('Share action was not successful or was unavailable: ${result.status}');
        return Left(GenericFailure('Could not open share dialog. Status: ${result.status}.'));
      }

    } catch (e) {
      appLogger.e('Error exporting tasks: $e');
      return Left(GenericFailure('Failed to export tasks: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<Task>>> importTasks() async {
    try {
      // file_picker handles its own permissions for picking files.
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Tasks JSON File',
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        
        // Defensive decoding
        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(jsonString);
        } catch (e) {
          appLogger.e('Error decoding JSON from file: $e');
          return Left(GenericFailure('Invalid JSON file format.'));
        }

        if (decodedJson is! List) {
          appLogger.w('Imported JSON is not a list: ${decodedJson.runtimeType}');
          return Left(GenericFailure('Invalid data format: Expected a list of tasks.'));
        }
        
        final List<dynamic> jsonList = decodedJson;
        
        final List<Task> importedTasks = jsonList.map((jsonTask) {
          try {
            if (jsonTask is Map<String, dynamic>) {
              return Task.fromJson(jsonTask);
            }
            appLogger.w('Skipping invalid task data during import (not a map): $jsonTask');
            return null;
          } catch (e) {
            appLogger.w('Skipping invalid task data during import (fromJson error): $jsonTask, Error: $e');
            return null;
          }
        }).whereType<Task>().toList();

        appLogger.i('Successfully parsed ${importedTasks.length} tasks from ${file.path}');
        return Right(importedTasks);
      } else {
        appLogger.i('File import cancelled by user or no file selected.');
        return Left(GenericFailure('No file selected for import.'));
      }
    } catch (e) {
      appLogger.e('Error importing tasks: $e');
      return Left(GenericFailure('Failed to import tasks: ${e.toString()}'));
    }
  }
}