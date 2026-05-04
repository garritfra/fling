# fling_api.api.MeApi

## Load the API package
```dart
import 'package:fling_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**v1MeGet**](MeApi.md#v1meget) | **GET** /v1/me | 
[**v1MePatch**](MeApi.md#v1mepatch) | **PATCH** /v1/me | 


# **v1MeGet**
> Me v1MeGet()



### Example
```dart
import 'package:fling_api/api.dart';

final api = FlingApi().getMeApi();

try {
    final response = api.v1MeGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->v1MeGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Me**](Me.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **v1MePatch**
> Me v1MePatch(patchMe)



### Example
```dart
import 'package:fling_api/api.dart';

final api = FlingApi().getMeApi();
final PatchMe patchMe = ; // PatchMe | 

try {
    final response = api.v1MePatch(patchMe);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->v1MePatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **patchMe** | [**PatchMe**](PatchMe.md)|  | 

### Return type

[**Me**](Me.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

