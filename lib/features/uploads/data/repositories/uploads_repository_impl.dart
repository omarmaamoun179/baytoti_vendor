import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/uploaded_image.dart';
import '../../domain/repositories/uploads_repository.dart';
import '../datasources/uploads_data_source.dart';

class UploadsRepositoryImpl implements UploadsRepository {
  final UploadsDataSource _dataSource;

  UploadsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, UploadedImage>> uploadImage(String localPath) =>
      _dataSource.uploadImage(localPath);
}
