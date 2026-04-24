# fling_api.api.DefaultApi

## Load the API package
```dart
import 'package:fling_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**v1HealthzGet**](DefaultApi.md#v1healthzget) | **GET** /v1/healthz | 


# **v1HealthzGet**
> Health v1HealthzGet()



### Example
```dart
import 'package:fling_api/api.dart';

final api = FlingApi().getDefaultApi();

try {
    final response = api.v1HealthzGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DefaultApi->v1HealthzGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Health**](Health.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

