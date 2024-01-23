# network_service

## Basic Configuration

1. Add following line on your main app to configure your network service where you can add your base
   url
   NetworkService.configureNetworkService($baseURL);

## How to use network service, for get, post, delete?

### For POST method
- NetworkService.apiRequest.getResponse(
  endPoint: "your_api_path",
  apiMethods: ApiMethods.post,
  body: { }
  );

### For GET method
- NetworkService.apiRequest.getResponse(
  endPoint: "your_api_path",
  apiMethods: ApiMethods.get,
  queryParams: { }
  );

### For DELETE method
- NetworkService.apiRequest.getResponse(
  endPoint: "your_api_path",
  apiMethods: ApiMethods.delete,
  body: { }
  );

Note: If you want to cache any http request, make sure to use isToCache boolean. By default its value is true